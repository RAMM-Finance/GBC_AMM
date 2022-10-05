// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// Uncomment this line to use console.log
// import "hardhat/console.sol";
// import {ERC20} from "./aave/Libraries.sol"; 
import {SafeCast,IERC20Minimal, FixedPointMath, ERC20} from "./libraries.sol"; 
import "forge-std/console.sol";

/// @notice AMM for a token pair (trade, base), only tracks price denominated in trade/base  
/// and point-bound(limit order) and range-bound(multiple points, also known as concentrated) liquidity 
/// @dev all funds will be handled in the child contract 
contract GranularBondingCurve{
    using FixedPointMath for uint256;
    using Tick for mapping(uint16 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    constructor(
        address _baseToken,
        address _tradeToken
        //uint256 _priceDelta
        ) {
        tradeToken = _tradeToken; 
        baseToken = _baseToken; 
        //priceDelta = _priceDelta; 

        fee =0; 
        factory = address(0); 
        tickSpacing = 0; 

        //Start liquidity 
        liquidity = 100 * uint128(PRECISION); 
    }


    uint24 public immutable  fee;
    Slot0 public slot0; 
    address public immutable  factory;
    address public immutable  tradeToken;
    address public immutable  baseToken;

    int24 public immutable  tickSpacing;

    uint128 public liquidity; 

    mapping(uint16 => Tick.Info) public  ticks;

    mapping(bytes32 => Position.Info) public  positions;

    // mapping(uint16=> PricePoint) Points; 

    uint256 public  constant priceDelta = 1e16; //difference in price for two adjacent ticks

    uint256 public constant PRECISION = 1e18; 

    /// @notice previliged function called by the market maker 
    /// if he is the one providing all the liquidity 
    function setLiquidity()public{}

    function positionIsFilled(
        address recipient, 
        uint16 point, 
        bool isAsk) 
        public view returns(bool){
        Position.Info storage position = positions.get(recipient, point, point+1);

        uint128 numCross = ticks.getNumCross(point, isAsk); 
        uint128 crossId = isAsk? position.askCrossId : position.bidCrossId; 
        uint128 liq = isAsk? position.askLiq : position.bidLiq;

        return (liq>0 && numCross > crossId); 
    }

    function setPriceAndPoint(uint256 price) public {
        slot0.curPrice = price; 
        slot0.point = priceToPoint(price); 
    }

    function getCurPrice() public view returns(uint256){
        return slot0.curPrice; 
    }
    function getOneTimeLiquidity(uint16 point, bool moveUp) public view returns(uint256){
        return uint256(ticks.oneTimeLiquidity(point, moveUp)); 
    }    

    function getNumCross(uint16 point, bool moveUp) public view returns(uint256){
        return ticks.getNumCross(point, moveUp); 
    }

    function bidsLeft(uint16 point) public view returns(uint256){
    }


    struct Slot0 {
        // the current price
        uint256 curPrice;
        // the current tick
        uint16 point;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;

        // whether the pool is locked
        bool unlocked;


    }


   struct SwapCache {
        // the protocol fee for the input token
        uint8 feeProtocol;
        // liquidity at the beginning of the swap
        uint128 liquidityStart;
        // the timestamp of the current block
        uint32 blockTimestamp;
        // the current value of the tick accumulator, computed only if we cross an initialized tick
        int56 tickCumulative;
        // the current value of seconds per liquidity accumulator, computed only if we cross an initialized tick
        uint160 secondsPerLiquidityCumulativeX128;
        // whether we've computed and cached the above two accumulators
        bool computedLatestObservation;
    }


    // the top level state of the swap, the results of which are recorded in storage at the end
    struct SwapState {
        // the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        uint256 amountCalculated;
        // current sqrt(price)
        uint256 curPrice;
        // the tick associated with the current price
        uint16 point;
        // the global fee growth of the input token
        uint256 feeGrowthGlobalX128;
        // amount of input token paid as protocol fee
        uint128 protocolFee;
        // the current liquidity in range
        uint128 liquidity;

        uint256 a; 
        uint256 b; 
        uint256 s;


    }

    struct StepComputations {
        // the price at the beginning of the step
        uint256 priceStart;
        // the next tick to swap to from the current tick in the swap direction
        uint16 pointNext;
        // whether tickNext is initialized or not
        bool initialized;
        // price for the next tick (1/0)
        uint256 priceNextLimit;
        // how much is being swapped in in this step
        uint256 amountIn;
        // how much is being swapped out
        uint256 amountOut;
        // how much fee is being paid in
        uint256 feeAmount;

        uint128 liqDir; 
        uint128 liqOpp; 
    }



    /// param +amountSpecified is in base if moveUp, else is in trade
    /// -amountSpecified is in trade if moveUp, else is in base 
    /// returns amountIn if moveUp, cash, else token
    /// returns amountOut if moveUp, token, else cash 
    function trade(
        address recipient, 
        bool moveUp, 
        int256 amountSpecified, 
        uint256 priceLimit, 
        bytes calldata data
        ) public returns(uint256 amountIn, uint256 amountOut){
        //require(msg.sender == entry, "ENTRY ERR"); 
        console.logString('---New Trade---'); 
        Slot0 memory slot0Start = slot0; 
        uint256 pDelta = priceDelta; 

        SwapCache memory cache = SwapCache({
            feeProtocol: 0, 
            liquidityStart: liquidity, 
            blockTimestamp: uint32(block.timestamp),
            tickCumulative: 0, 
            secondsPerLiquidityCumulativeX128: 0, 
            computedLatestObservation:false
            }); 

        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amountSpecified, 
            amountCalculated: 0, 
            curPrice: slot0Start.curPrice,
            feeGrowthGlobalX128: 0, 
            protocolFee: 0, 
            liquidity: cache.liquidityStart, 
            point: slot0.point, 
            a: 0, 
            b: 0, 
            s: 0

            }); 

        bool exactInput = amountSpecified > 0;

        // increment price by 1/1e18 if at boundary, should be negligible compared to fees 
        if (mod0(state.curPrice, pDelta) && !moveUp) state.curPrice += 1; 

        while (state.amountSpecifiedRemaining !=0 && state.curPrice != priceLimit){
            StepComputations memory step; 

            step.priceStart = state.curPrice; 
            step.priceNextLimit = getNextPriceLimit(state.point, pDelta, moveUp); 
            step.pointNext = moveUp? state.point + 1 : state.point-1; 

            // Need liquidity for both move up and move down for path independence within a 
            // given point range. Either one of them should be 0 
            step.liqDir = ticks.oneTimeLiquidity(state.point, moveUp); 
            step.liqOpp = ticks.oneTimeLiquidity(state.point, !moveUp); 
            assert(step.liqOpp ==0 || step.liqDir == 0); 

            state.a = inv(state.liquidity + step.liqDir + step.liqOpp); 
            state.b = yInt(state.curPrice, moveUp); 
            state.s = xMax(state.curPrice, state.b, state.a); 

            {console.log('________'); 
            console.log('CURPRICE', state.curPrice); 
            console.log('trading; liquidity, price', state.liquidity, state.curPrice ); 
            console.log('nextpricelimit/pointnext', step.priceNextLimit, step.pointNext); 
            console.log('liquidities', uint256(step.liqDir), uint256(step.liqOpp));  
            console.log('a', state.a); }

            //If moveup, amountIn is in cash, amountOut is token and vice versa 
            (state.curPrice, step.amountIn, step.amountOut) = swapStep(
                state.curPrice, 
                step.priceNextLimit,    
                state.amountSpecifiedRemaining, 
                fee, 
                state.a, 
                state.s, 
                state.b
                ); 
            console.log('amountinandout', step.amountIn, step.amountOut); 
            console.log('s,b', state.s, state.b); 

            if (exactInput){
                state.amountSpecifiedRemaining -= int256(step.amountIn + step.feeAmount); 
            }
            else{
                state.amountSpecifiedRemaining += int256(step.amountIn + step.feeAmount); 
            }
            state.amountCalculated += step.amountOut; 

            // If next limit reached, cross price range and change slope(liquidity)
            if (state.curPrice == step.priceNextLimit){
                
                int128 liquidityNet = ticks.cross(
                    step.pointNext
                    ); 

                // If crossing UP, asks are all filled so need to set askLiquidity to 0 and increment numCross
                if (moveUp) ticks.deleteOneTimeLiquidity(state.point, true); 

                // If crossing DOWN, bids are all filled 
                else{
                    liquidityNet = -liquidityNet; 
                    ticks.deleteOneTimeLiquidity(state.point, false); 
                }

                state.liquidity = addDelta(state.liquidity,liquidityNet);

                console.log('liquiditynet, newprice', uint256(int256(liquidityNet)), state.curPrice); 
                state.point = step.pointNext;  
            }

        }

        if(state.point != slot0Start.point){
            (slot0.curPrice, slot0.point) = (state.curPrice, state.point); 
        }

        if (cache.liquidityStart != state.liquidity) liquidity = state.liquidity;

        (amountIn, amountOut) = exactInput
                                ? (uint256(amountSpecified), state.amountCalculated)
                                : (state.amountCalculated, uint256(-amountSpecified)); 

        if (moveUp) {
            handleBuys(recipient, amountOut, amountIn); 

        }
        else{
            handleSells(recipient, amountOut, amountIn); 
       
        }


    }

    /// @dev should be inherited and modified within the child 
    function handleBuys(address recipient, uint256 amountOut, uint256 amountIn) internal virtual {  
        // Mint and Pull 
        console.log('mint/pull amount,', amountOut, amountIn); 
    }

    function handleSells(address recipient, uint256 amountOut, uint256 amountIn) internal virtual {}

    function placeLimitOrder(
        address recipient, 
        uint16 point, 
        uint128 amount,
        bool isAsk  
        ) public returns(uint256 amountToEscrow, uint128 numCross ){   

        // Should only accept asks for price above the current point range
        if(isAsk && pointToPrice(point) <= slot0.curPrice) revert("ask below prie"); 
        else if(!isAsk && pointToPrice(point) >= slot0.curPrice) revert("bids above prie"); 

        Position.Info storage position = positions.get(recipient, point, point+1);

        numCross = ticks.getNumCross(point, isAsk); 
        position.updateLimit(int128(amount), isAsk, numCross); 

        ticks.updateOneTimeLiquidity( point, int128(amount), isAsk); 

        // If placing bids, need to escrow baseAsset, vice versa 
        address tokenToEscrow = isAsk? tradeToken : baseToken;

        amountToEscrow = isAsk
                ? tradeGivenLiquidity(
                    pointToPrice(point+1), 
                    pointToPrice(point), 
                    uint256(amount) 
                    )
            
                : baseGivenLiquidity(
                    pointToPrice(point+1), 
                    pointToPrice(point), 
                    uint256(amount) 
                    ); 

        console.log('amountbid', amountToEscrow); 


    }

    function reduceLimitOrder(
        address recipient, 
        uint16 point, 
        uint128 amount,
        bool isAsk 
        ) public {

        Position.Info storage position = positions.get(msg.sender, point, point+1);

        position.updateLimit(-int128(amount), isAsk, 0); 

        ticks.updateOneTimeLiquidity(point, -int128(amount), isAsk); 

        address tokenToReturn = isAsk? tradeToken : baseToken;
        
        uint256 amountToReturn = isAsk
                ? baseGivenLiquidity(
                    pointToPrice(point+1), 
                    pointToPrice(point), 
                    uint256(amount) 
                    )
             
                : tradeGivenLiquidity(
                    pointToPrice(point+1), 
                    pointToPrice(point), 
                    uint256(amount) 
                    );
               

        ERC20(tokenToReturn).transfer(
            recipient,
            amountToReturn
            ); 


    }

    /// @notice Need to check if the ask/bids were actually filled, which is equivalent to
    /// the condition that numCross > crossId, because numCross only increases when crossUp 
    /// or crossDown 
    function claimFilledOrder(
        address recipient, 
        uint16 point, 
        bool isAsk 
        ) public returns(uint256 claimedAmount){
        Position.Info storage position = positions.get(recipient, point, point+1);

        uint128 numCross = ticks.getNumCross(point, isAsk); 
        uint128 crossId = isAsk? position.askCrossId : position.bidCrossId; 
        require(numCross > crossId, "Position not filled");

        uint128 liq = isAsk? position.askLiq : position.bidLiq;

        // Sold to base when asks are filled
        if(isAsk) claimedAmount = baseGivenLiquidity(
                pointToPrice(point+1), 
                pointToPrice(point), 
                uint256(liq) 
                ); 

        // Bought when bids are filled so want tradeTokens
        else claimedAmount = tradeGivenLiquidity(
                pointToPrice(point+1), 
                pointToPrice(point), 
                uint256(liq) 
                ); 

        position.updateLimit(-int128(liq), isAsk, 0); 
        
        // Need to burn AND 

    }

    struct ModifyPositionParams {
        // the address that owns the position
        address owner;
        // the lower and upper tick of the position
        uint16 pointLower;
        uint16 pointUpper;
        // any change in liquidity
        int128 liquidityDelta;
    }

    /// @notice provides liquidity in range or adds limit order if pointUpper = pointLower + 1
    function provide(
        address recipient, 
        uint16 pointLower, 
        uint16 pointUpper, 
        uint128 amount, 
        bytes calldata data 

        ) public returns(uint256 amount0, uint256 amount1 ){
        require(amount > 0, "0 amount"); 

        (,  amount0,  amount1) = _modifyPosition(
            ModifyPositionParams({
                owner: recipient, 
                pointLower : pointLower, 
                pointUpper: pointUpper, 
                liquidityDelta: int128(amount)//.toInt128()
                })
            ); 

        //mintCallback

    }

    function remove(
        address recipient, 
        uint16 pointLower, 
        uint16 pointUpper, 
        uint128 amount
        ) public returns(uint256 , uint256 ){

        (Position.Info storage position,  uint256 amount0, uint256 amount1) = _modifyPosition(
            ModifyPositionParams({
                owner: recipient, 
                pointLower : pointLower, 
                pointUpper: pointUpper, 
                liquidityDelta: -int128(amount)//.toInt128()
                })
            ); 

        if(amount0>0 || amount1> 0){
            (position.tokensOwed0, position.tokensOwed1) = (
                position.tokensOwed0 + amount0,
                position.tokensOwed1 + amount1
            );
        }
        return (amount0, amount1); 

    }

    function collect(
        address recipient,
        uint16 tickLower,
        uint16 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) public  returns (uint256 amount0, uint256 amount1) {
        // we don't need to checkTicks here, because invalid positions will never have non-zero tokensOwed{0,1}
        Position.Info storage position = positions.get(msg.sender, tickLower, tickUpper);

        amount0 = amount0Requested > position.tokensOwed0 ? position.tokensOwed0 : amount0Requested;
        amount1 = amount1Requested > position.tokensOwed1 ? position.tokensOwed1 : amount1Requested;

        if (amount0 > 0) {
            position.tokensOwed0 -= amount0;
            safeTransfer(baseToken, recipient, amount0);
        }
        if (amount1 > 0) {
            position.tokensOwed1 -= amount1;
            safeTransfer(tradeToken, recipient, amount1);
        }

    }


    function _modifyPosition(ModifyPositionParams memory params)
    private 
    returns(
        Position.Info storage position, 
        uint256 baseAmount, 
        uint256 tradeAmount
        )
    {
        Slot0 memory _slot0 = slot0; // SLOAD for gas optimization

        position = _updatePosition(
            params.owner,
            params.pointLower,
            params.pointUpper,
            params.liquidityDelta,
            _slot0.point
        );

        if (params.liquidityDelta != 0){
            if (_slot0.point < params.pointLower){
                // in case where liquidity is just asks waiting to be sold into, 
                // so need to only provide tradeAsset 
                tradeAmount = tradeGivenLiquidity(
                    pointToPrice(params.pointUpper), 
                    pointToPrice(params.pointLower), 
                    params.liquidityDelta >= 0
                        ? uint256(int256(params.liquidityDelta))
                        : uint256(int256(-params.liquidityDelta))
                    ); 
            } else if( _slot0.point < params.pointUpper){
                uint128 liquidityBefore = liquidity; 

                // Get total asks to be submitted above current price
                tradeAmount = tradeGivenLiquidity(
                    pointToPrice(params.pointUpper),
                    _slot0.curPrice, 
                    params.liquidityDelta >= 0
                        ? uint256(int256(params.liquidityDelta))
                        : uint256(int256(-params.liquidityDelta))
                    ); 

                // Get total bids to be submitted below current price 
                baseAmount = baseGivenLiquidity(
                    _slot0.curPrice, 
                    pointToPrice(params.pointLower), 
                    params.liquidityDelta >= 0
                        ? uint256(int256(params.liquidityDelta))
                        : uint256(int256(-params.liquidityDelta))
                    ); 

                // Slope changes since current price is in this range 
                liquidity = addDelta(liquidityBefore, params.liquidityDelta);

            } else{
                // liquidity is just bids waiting to be bought into 
                baseAmount = baseGivenLiquidity(
                    pointToPrice(params.pointUpper), 
                    pointToPrice(params.pointLower), 
                    params.liquidityDelta >= 0
                        ? uint256(int256(params.liquidityDelta))
                        : uint256(int256(-params.liquidityDelta))
                ); 
            }
        }
    }


    function _updatePosition(
        address owner, 
        uint16 pointLower, 
        uint16 pointUpper, 
        int128 liquidityDelta, 
        uint16 point 
        ) private returns(Position.Info storage position){

        position = positions.get(owner, pointLower, pointUpper); 

        bool flippedLower; 
        bool flippedUpper; 

        if(liquidityDelta != 0){

            flippedLower = ticks.update(
                pointLower, 
                point, 
                liquidityDelta, 
                false
                ); 

            flippedUpper = ticks.update(
                pointUpper, 
                point, 
                liquidityDelta, 
                true
                ); 
        } 

        position.update(liquidityDelta, 0,0); 
    }


    /// @notice Compute results of swap given amount in and params
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @param a is the inverseLiquidity, the slope of the curve at current price range 
    /// b is 0 and s is curPrice/a during variable liquidity phase
    function swapStep(
        uint256 curPrice, 
        uint256 targetPrice, 
        int256 amountRemaining, 
        uint24 feePips,

        uint256 a, 
        uint256 s,
        uint256 b
        ) 
        public 
        pure 
        returns(uint256 nextPrice, uint256 amountIn, uint256 amountOut ){

        bool moveUp = targetPrice >= curPrice; 
        bool exactInput = amountRemaining >= 0; 
        //uint256 amountRemainingLessFee = amountRemaining.mulDiv(1e6 - feePips, 1e6);
        uint256 amountRemainingLessFee = uint256(amountRemaining); 

        // If move up and exactInput, amountIn is base, amountOut is trade 
        if (exactInput){

            if (moveUp){
                (amountOut, nextPrice) = amountOutGivenIn(amountRemainingLessFee,s,a,b, true); 

                // If overshoot go to next point
                if (nextPrice >= targetPrice){
                    nextPrice = targetPrice; 

                    // max amount out for a given price range is Pdelta / a 
                    amountOut = (targetPrice - curPrice).divWadDown(a); 
                    amountIn = areaUnderCurve(amountOut, s,a,b); 
                }

                // Completely filled within this point 
                else {
                    amountIn = amountRemainingLessFee; 
                }   
            }

            // amountIn is trade, amountOut is base 
            else {
                // If amount is greater than s, then need to cap it 
                (amountOut, nextPrice) = amountOutGivenIn(min(amountRemainingLessFee,s), s,a,b,false); 

                // If undershoot go to previous point 
                if(nextPrice <= targetPrice){
                    nextPrice = targetPrice; 

                    // max amount out is area under curve 
                    amountIn = (curPrice - targetPrice).divWadDown(a);
                    amountOut = areaUnderCurve(amountIn, 0,a,b); 
                }
                else{
                    amountIn = amountRemainingLessFee; 
                }
            }

        }

        else {
            if(moveUp){
                amountIn = min(amountRemainingLessFee, xMax( targetPrice,  b,  a)); 
                amountOut = areaUnderCurve(amountIn, 0, a, b); 
                nextPrice = a.mulWadDown(amountIn) + b; 
            }
            else{
                //TODO 
            }
        }

        

        }

  
    /// @dev tokens returned = [((a*s + b)^2 + 2*a*p)^(1/2) - (a*s + b)] / a
    /// @param amount: amount cash in
    /// returns amountDelta wanted token returned 
    function amountOutGivenIn( 
        uint256 amount,
        uint256 s, 
        uint256 a, 
        uint256 b, 
        bool up) 
        internal 
        pure 
        returns(uint256 amountDelta, uint256 resultPrice) {
        
        if (up){
            uint256 x = ((a.mulWadDown(s) + b) ** 2)/PRECISION; 
            uint256 y = 2*( a.mulWadDown(amount)); 
            uint256 x_y_sqrt = ((x+y)*PRECISION).sqrt();
            uint256 z = (a.mulWadDown(s) + b); 
            amountDelta = (x_y_sqrt-z).divWadDown(a);
            resultPrice = a.mulWadDown(amountDelta + s) + b; 
        }

        else{
            uint256 z = b + a.mulWadDown(s) - a.mulWadDown(amount)/2;  
            amountDelta = amount.mulWadDown(z); 
            resultPrice = a.mulWadDown(s-amount) + b; 
        }


    }

      /// @notice calculates area under the curve from s to s+amount
      /// result = a * amount / 2  * (2* supply + amount) + b * amount
      /// returned in collateral decimals
    function areaUnderCurve(
        uint256 amount, 
        uint256 s, 
        uint256 a, 
        uint256 b) 
        internal
        pure 
        returns(uint256 area){

        area = ( a.mulWadDown(amount) / 2 ).mulWadDown(2 * s + amount) + b.mulWadDown(amount); 
    }



    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }

    function getMaxLiquidity() public view returns(uint256){
        // ticks.corrs
    }

    function tradeGivenLiquidity(uint256 p2, uint256 p1, uint256 L) public pure returns(uint256){
        require(p2>=p1, "price ERR"); 
        return (p2-p1).mulWadDown(L); 
    }

    function baseGivenLiquidity(uint256 p2, uint256 p1, uint256 L) public pure returns(uint256) {
        require(p2>=p1, "price ERR"); 
        return areaUnderCurve(tradeGivenLiquidity(p2, p1, L), 0, inv(L), p1); 
    }

    function liquidityGivenTrade() public pure returns(uint256){}
    function liquidityGivenBase() public pure returns(uint256){}

    function pointToPrice(uint16 point) public pure returns(uint256){
        return(uint256(point) * priceDelta); 
    }

    /// @notice will round down to nearest integer 
    function priceToPoint(uint256 price) public pure returns(uint16){
        return uint16((price.divWadDown(priceDelta))/PRECISION); 
    }

    function xMax(uint256 curPrice, uint256 b, uint256 a) public pure returns(uint256){
        return (curPrice-b).divWadDown(a); 
    }

    /// @notice get the lower bound of the given price range, or the y intercept of the curve of
    /// the current point
    function yInt(uint256 curPrice, bool moveUp) public pure returns(uint256){
        uint16 point = priceToPoint(curPrice); 

        // If at boundary when moving down, decrement point by one
        return (!moveUp && (curPrice%point == 0))? pointToPrice(point-1) : pointToPrice(point); 
    }

    function getNextPriceLimit(uint16 point, uint256 pDelta, bool moveUp) public pure returns(uint256){
        if (moveUp) return uint256(point+1) * pDelta; 
        else return uint256(point) * pDelta; 
    }

    function inv(uint256 l) public pure returns(uint256){
        return PRECISION.divWadDown(l); 
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }
    function mod0(uint256 a, uint256 b) internal pure returns(bool){
        return (a%b ==0); 
    }
    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta(uint128 x, int128 y) public pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }
    function getLiq(address to, uint16 point, bool isAsk) public view returns(uint128){
        return  isAsk
                ? positions.get(msg.sender, point, point+1).askLiq
                : positions.get(msg.sender, point, point+1).bidLiq; 
    }


}



/// @title Position
/// @notice Positions represent an owner address' liquidity between a lower and upper tick boundary
/// @dev Positions store additional state for tracking fees owed to the position
library Position {
    using FixedPointMath for uint256;

    // info stored for each user's position
    struct Info {
        uint128 bidCrossId; 
        uint128 askCrossId; 
        uint128 askLiq; 
        uint128 bidLiq; 

        // the amount of liquidity owned by this position
        uint128 liquidity;
        // fee growth per unit of liquidity as of the last update to liquidity or fees owed
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // the fees owed to the position owner in token0/token1
        uint256 tokensOwed0;
        uint256 tokensOwed1;

        
    }

    function updateLimit(
        Info storage self,
        int128 limitLiqudityDelta, 
        bool isAsk, 
        uint128 crossId
        ) internal {

        if (isAsk) {
            self.askLiq = addDelta(self.askLiq, limitLiqudityDelta);
            if( limitLiqudityDelta > 0) self.askCrossId = crossId; 
        } 

        else {
            self.bidLiq = addDelta(self.bidLiq, limitLiqudityDelta); 
            if( limitLiqudityDelta > 0) self.bidCrossId = crossId; 
        }
    }

    /// @notice Returns the Info struct of a position, given an owner and position boundaries
    /// @param self The mapping containing all user positions
    /// @param owner The address of the position owner
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @return position The position info struct of the given owners' position
    function get(
        mapping(bytes32 => Info) storage self,
        address owner,
        uint16 tickLower,
        uint16 tickUpper
    ) internal view returns (Position.Info storage position) {
        position = self[keccak256(abi.encodePacked(owner, tickLower, tickUpper))];
    }

    /// @notice Credits accumulated fees to a user's position
    /// @param self The individual position to update
    /// @param liquidityDelta The change in pool liquidity as a result of the position update
    /// @param feeGrowthInside0X128 The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    /// @param feeGrowthInside1X128 The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function update(
        Info storage self,
        int128 liquidityDelta,
        uint256 feeGrowthInside0X128,
        uint256 feeGrowthInside1X128
    ) internal {
        Info memory _self = self;

        uint128 liquidityNext;
        if (liquidityDelta == 0) {
            require(_self.liquidity > 0, 'NP'); // disallow pokes for 0 liquidity positions
            liquidityNext = _self.liquidity;
        } else {
            liquidityNext = addDelta(_self.liquidity, liquidityDelta);
        }

        // calculate accumulated fees
        uint128 tokensOwed0 =_self.liquidity; 
            // uint128(
            //     FixedPointMathLib.mulDiv(
            //         feeGrowthInside0X128 - _self.feeGrowthInside0LastX128,
            //         _self.liquidity,
            //         FixedPoint128.Q128
            //     )
            // );
        uint128 tokensOwed1 =_self.liquidity; 
            // uint128(
            //     FixedPointMathLib.mulDiv(
            //         feeGrowthInside1X128 - _self.feeGrowthInside1LastX128,
            //         _self.liquidity,
            //         FixedPoint128.Q128
            //     )
            // );

        // update the position
        if (liquidityDelta != 0) self.liquidity = liquidityNext;
        self.feeGrowthInside0LastX128 = feeGrowthInside0X128;
        self.feeGrowthInside1LastX128 = feeGrowthInside1X128;
        if (tokensOwed0 > 0 || tokensOwed1 > 0) {
            // overflow is acceptable, have to withdraw before you hit type(uint128).max fees
            self.tokensOwed0 += tokensOwed0;
            self.tokensOwed1 += tokensOwed1;
        }
    }
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }
}

/// @title Tick
/// @notice Contains functions for managing tick processes and relevant calculations
library Tick {
    using FixedPointMath for uint256;

    using SafeCast for int256;

    // info stored for each initialized individual tick
    struct Info {
        // the total position liquidity that references this tick
        uint128 liquidityGross;
        // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
        int128 liquidityNet;
        // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        // the cumulative tick value on the other side of the tick
        int56 tickCumulativeOutside;
        // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint160 secondsPerLiquidityOutsideX128;
        // the seconds spent on the other side of the tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint32 secondsOutside;
        // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
        // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
        bool initialized;

        uint128 askLiquidityGross; 
        uint128 bidLiquidityGross;
        uint128 askNumCross; 
        uint128 bidNumCross; 
    }

    function getNumCross(
        mapping(uint16=> Tick.Info) storage self, 
        uint16 tick, 
        bool isAsk
        ) internal view returns(uint128){
        return isAsk? self[tick].askNumCross : self[tick].bidNumCross; 
    }

    function oneTimeLiquidity(
        mapping(uint16=> Tick.Info) storage self, 
        uint16 tick, 
        bool isAsk 
        ) internal view returns(uint128){
        return isAsk? self[tick].askLiquidityGross : self[tick].bidLiquidityGross ; 
    }

    function deleteOneTimeLiquidity(
        mapping(uint16=> Tick.Info) storage self, 
        uint16 tick, 
        bool isAsk
        ) internal {
        if(isAsk) {
            self[tick].askLiquidityGross = 0;
            self[tick].askNumCross++; 
        }
        else {
            self[tick].bidLiquidityGross = 0; 
            self[tick].bidNumCross++; 
        }
    }

    function updateOneTimeLiquidity(
        mapping(uint16=> Tick.Info) storage self, 
        uint16 tick, 
        int128 oneTimeLiquidityDelta,
        bool isAsk
        ) internal {
        if (isAsk) self[tick].askLiquidityGross = addDelta(self[tick].askLiquidityGross, oneTimeLiquidityDelta); 
        else self[tick].bidLiquidityGross = addDelta(self[tick].bidLiquidityGross, oneTimeLiquidityDelta);
    }

    function update(
        mapping(uint16 => Tick.Info) storage self,
        uint16 tick,
        uint16 tickCurrent,
        int128 liquidityDelta,
        bool upper
    ) internal returns (bool flipped) {
        Tick.Info storage info = self[tick];

        uint128 liquidityGrossBefore = info.liquidityGross; 
        uint128 liquidityGrossAfter = addDelta(liquidityGrossBefore, liquidityDelta); 

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        if(liquidityGrossBefore == 0) info.initialized = true; 

        info.liquidityGross = liquidityGrossAfter;

        info.liquidityNet = upper 
            ? (int256(info.liquidityNet)-liquidityDelta).toInt128()
            : (int256(info.liquidityNet)+liquidityDelta).toInt128(); 


    }


    function clear(mapping(uint16 => Tick.Info) storage self, uint16 tick) internal {
        delete self[tick];
    }


    function cross(
        mapping(uint16 => Tick.Info) storage self,
        uint16 tick
        // uint256 feeGrowthGlobal0X128,
        // uint256 feeGrowthGlobal1X128,
        // uint160 secondsPerLiquidityCumulativeX128,
        // int56 tickCumulative,
        // uint32 time
    ) internal returns (int128 liquidityNet) {
        Tick.Info storage info = self[tick]; 

        liquidityNet = info.liquidityNet; 
 
    }

    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }
}


contract SpotPool is GranularBondingCurve{

    ERC20 BaseToken; 
    ERC20 TradeToken; 

    constructor(
        address _baseToken, 
        address _tradeToken
        )GranularBondingCurve(_baseToken,_tradeToken){
        BaseToken = ERC20(_baseToken); 
        TradeToken = ERC20(_tradeToken); 
    }

    function handleBuys(address recipient, uint256 amountOut, uint256 amountIn) internal override{

        TradeToken.transfer(recipient, amountOut); 
        BaseToken.transferFrom(recipient, address(this), amountIn);
    }

    function handleSells(address recipient, uint256 amountOut, uint256 amountIn) internal override{

        BaseToken.transfer(recipient, amountOut); 
        TradeToken.transferFrom(recipient, address(this), amountIn);
    }

    /// @notice if buyTradeForBase, move up, and vice versa 
    function takerTrade(
        bool buyTradeForBase, 
        int256 amountIn,
        uint256 priceLimit, 
        bytes calldata data        
        ) external {

        trade(
            msg.sender, 
            buyTradeForBase, 
            amountIn,  
            priceLimit, 
            data
        ); 

    }


    function makerTrade(
        bool buyTradeForBase,
        uint256 amountIn,
        uint16 point
        ) external {

        (uint256 toEscrowAmount, uint128 crossId) = placeLimitOrder(msg.sender, point, uint128(amountIn), !buyTradeForBase); 

        // Collateral for bids
        if (buyTradeForBase) BaseToken.transferFrom(msg.sender, address(this), toEscrowAmount); 

        // or asks
        else TradeToken.transferFrom(msg.sender, address(this), toEscrowAmount); 

    }

    function makerClaim(
        uint16 point, 
        bool buyTradeForBase
        ) external {
        uint256 claimedAmount = claimFilledOrder(
            msg.sender, 
            point, 
            !buyTradeForBase
        ); 

        if (buyTradeForBase) TradeToken.transfer(msg.sender, claimedAmount);
        else BaseToken.transfer(msg.sender, claimedAmount); 

    }
}



/// @notice Uses AMM as a derivatives market,where the price is bounded between two price
/// and mints/burns tradeTokens. 
/// stores all baseTokens for trading, and also stores tradetokens when providing liquidity, 
/// @dev Short loss is bounded as the price is bounded, no need to program liquidations logic 
contract BoundedDerivativesPool {
    using FixedPointMath for uint256;
    // using Tick for mapping(uint16 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    // using Position for Position.Info;
    // uint256 constant PRECISION = 1e18; 
    ERC20 public  BaseToken; 
    ERC20 public  TradeToken; 
    ERC20 public  s_tradeToken; 
    GranularBondingCurve public pool; 
    uint256 public constant maxPrice = 1e18; 

    constructor(
        address base, 
        address trade, 
        address s_trade 
        // address _pool 
        ) 
   // GranularBondingCurve(base,trade)
    {
        BaseToken =  ERC20(base);

        TradeToken = ERC20(trade);
        s_tradeToken = ERC20(s_trade); 
        pool = new GranularBondingCurve(base,trade); 
        console.log('deployedd');  

    }


    function mintAndPull(address recipient, uint256 amountOut, uint256 amountIn) internal  {
        
        console.log('mint/pull amount,', amountOut, amountIn); 

        // Mint and Pull 
        TradeToken.mint(recipient, amountOut); 
        BaseToken.transferFrom(recipient,address(this), amountIn); 

    }

    function burnAndPush(address recipient, uint256 amountOut, uint256 amountIn) internal  {

        // Burn and Push 
        TradeToken.burn(recipient, amountIn); 
        BaseToken.transfer(recipient, amountOut); 
    }

    /// @notice Long up the curve, or short down the curve 
    /// param amountIn is base if long, trade if short
    /// param pricelimit is slippage tolerance
    function takerOpen(
        bool isLong, 
        int256 amountIn,
        uint256 priceLimit, 
        bytes calldata data
        ) external returns(uint256 poolamountIn, uint256 poolamountOut ){

        if(isLong){
            // Buy up 
            (poolamountIn, poolamountOut) = pool.trade(
                msg.sender, 
                true, 
                amountIn, 
                priceLimit, 
                data
            ); 
            mintAndPull(msg.sender, poolamountOut, poolamountIn);
        }

        else{
            //TODO negative amount, only works with postive now 
            // sell basetokens with this contract as the recipient
            (poolamountIn, poolamountOut) = pool.trade(
                address(this), 
                false, 
                int256(amountIn), 
                priceLimit, 
                data
            ); 

            // Escrow collateral required for shorting, where price for long + short = maxPrice, 
            // so (maxPrice-price of trade) * quantity
            BaseToken.transferFrom(msg.sender, address(this), poolamountIn.mulWadDown(maxPrice) - poolamountOut); 

            // One s_tradeToken is a representation of debt+sell of one tradetoken
            s_tradeToken.mint(msg.sender, uint256(amountIn)); 

        }

    }

    /// @param amountIn is trade if long, base if short 
    function takerClose(
        bool isLong, 
        int256 amountIn,
        uint256 priceLimit, 
        bytes calldata data
        ) external returns(uint256 poolamountIn, uint256 poolamountOut){

        // Sell down
        if(isLong){
            (poolamountIn, poolamountOut) = pool.trade(
                msg.sender, 
                false, 
                amountIn, //this should be trade tokens
                priceLimit, 
                data
            ); 
            burnAndPush(msg.sender, poolamountOut, poolamountIn);
        }

        else{
            
            // buy up with the baseToken that was transferred to this contract when opened
            (poolamountIn, poolamountOut) = pool.trade(
                address(this), 
                true, 
                amountIn, 
                priceLimit, 
                data
            ); 
            console.log('poolamountinandout', poolamountIn, poolamountOut); 
            // burn trader's shortTokens and transfer remaining base, which is (maxprice-price of trade) * quantity
            s_tradeToken.burn(msg.sender, poolamountOut); 
            BaseToken.transfer(msg.sender, poolamountOut.mulWadDown(maxPrice) - poolamountIn);
        }

    }

    /// @notice provides oneTimeliquidity in the range (point,point+1)
    /// @param amount is in liquidity 
    function makerOpen(
        uint16 point, 
        uint128 amount,
        bool isLong
        )external returns(uint256 toEscrowAmount, uint128 crossId){

        if(isLong){
            (toEscrowAmount, crossId) = pool.placeLimitOrder(msg.sender, point, amount, false); 

            BaseToken.transferFrom(msg.sender, address(this), toEscrowAmount); 
        }

        // need to set limit for sells, but claiming process is different then regular sells 
        else{
            (toEscrowAmount, crossId) = pool.placeLimitOrder(msg.sender, point, amount, true); 

            // escrow amount is (maxPrice - avgPrice) * quantity 
            uint256 escrowCollateral = toEscrowAmount - pool.baseGivenLiquidity(
                    pool.pointToPrice(point+1), 
                    pool.pointToPrice(point), 
                    uint256(amount) //positive since adding asks, not subtracting 
                    ); 
            BaseToken.transferFrom(msg.sender, address(this), escrowCollateral); 
            
            toEscrowAmount = escrowCollateral; 
        }

    }

    function makerClaimOpen(
        uint16 point, 
        bool isLong
        )external{

        if(isLong){
            uint256 claimedAmount = pool.claimFilledOrder(msg.sender, point, false ); 

            // user already escrowed funds, so need to send him tradeTokens 
            TradeToken.mint(msg.sender, claimedAmount);          
        }

        else{
            // open short is filled sells, check if sells are filled. If it is,
            // claimedAmount of basetokens should already be in this contract 
            uint256 claimedAmount = pool.claimFilledOrder(msg.sender, point, true ); 

            s_tradeToken.mint(msg.sender, 
                pool.tradeGivenLiquidity(
                    pool.pointToPrice(point+1), 
                    pool.pointToPrice(point), 
                    pool.getLiq(msg.sender, point, true)
                    )
                ); 
        }


    }
    function makerClose(
        uint16 point, 
        uint128 amount,
        bool isLong
        )external returns(uint256 toEscrowAmount, uint128 crossId){

        if(isLong){
            // close long is putting up trades for sells, 
            (toEscrowAmount, crossId) = pool.placeLimitOrder(msg.sender, point, amount, true); 
            //maybe burn it when claiming, and just escrow? 
            TradeToken.burn(msg.sender, toEscrowAmount); 
        }

        else{
            // Place limit orders for buys 
            (toEscrowAmount, crossId) = pool.placeLimitOrder(msg.sender, point, amount, true); 

            // Escrow s_tradeTokens,
            s_tradeToken.transferFrom(msg.sender, 
                address(this), 
                pool.tradeGivenLiquidity(
                    pool.pointToPrice(point+1), 
                    pool.pointToPrice(point), 
                    pool.getLiq(msg.sender, point, true)
                )
            ); 

        }

    }

    function makerClaimClose(
        uint16 point, 
        bool isLong
        ) external{

        if(isLong){
            // Sell is filled, so need to transfer back base 
            uint256 claimedAmount = pool.claimFilledOrder(msg.sender, point, false ); 
            BaseToken.transfer(msg.sender, claimedAmount); 
        }

        else{
            // Buy is filled, which means somebody burnt trade, so claimedAmount is in trade
            uint256 claimedAmount = pool.claimFilledOrder(msg.sender, point, true);

            BaseToken.transfer(msg.sender, claimedAmount.mulWadDown(maxPrice) 
                - pool.baseGivenLiquidity(
                    pool.pointToPrice(point+1), 
                    pool.pointToPrice(point), 
                    pool.getLiq(msg.sender, point, false)
                    )
                );

        }

    }    

    function provideLiquidity()external{}
    function withdrawLiquidity()external{}

}

