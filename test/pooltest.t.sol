// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GBC.sol";
import "../src/libraries.sol"; 
import "forge-std/console.sol";

contract PoolTest is Test {
    using FixedPointMath for uint256;
    uint256 constant PRECISION = 1e18; 
    BoundedDerivativesPool pool; 
    ERC20 baseToken; 
    ERC20 tradeToken; 
    ERC20 s_tradeToken; 
    function setUp() public {
        baseToken = new ERC20( "base",
        "base",
        18);
        tradeToken = new ERC20( "trade",
        "trade",
        18); 
        s_tradeToken = new ERC20("strade", "strade", 18); 

        pool = new BoundedDerivativesPool(address(baseToken), address(tradeToken), address(s_tradeToken), true); 

    }

    function testMaker() external {
        // bytes memory data; 

        // //maker shorts and taker longs 
        // (uint256 escrowAmount, uint128 crossId) = pool.makerOpen(61, uint128(500*PRECISION), false); 
        // console.log('escrowAmount', escrowAmount); 
        // (uint256 amountIn, uint256 amountOut) = pool.takerOpen(true, int256(escrowAmount), PRECISION, data );
        // console.log('amountin/out', amountIn, amountOut); 

        //maker longs and taker shorts 

    }
    function testMakerCloses() external{}
    function testMultiple() external{}

    function isClose(uint256 a, uint256 b, uint256 roundlimit) public pure returns(bool){

        return ( a <= b+roundlimit || a>= b-roundlimit); 
    }

    // function testIncrement() public {
    //     counter.increment();
    //     assertEq(counter.number(), 1);
    // }

    // function testSetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}



// contract TestPool{
//     using FixedPointMath for uint256;
//     uint256 constant PRECISION = 1e18; 
//     //GranularBondingCurve pool; 
//     BoundedDerivativesPool pool; 
//     ERC20 baseToken; 
//     ERC20 tradeToken; 
//     ERC20 s_tradeToken; 
//     constructor(){
//         baseToken = new ERC20( "base",
//         "base",
//         18);
//         tradeToken = new ERC20( "trade",
//         "trade",
//         18); 
//         s_tradeToken = new ERC20("strade", "strade", 18); 

//         //pool = new GranularBondingCurve(address(baseToken), address(tradeToken) );
//         // console.log('deploying'); 
//        // deployNewPool(); 
//         pool = new BoundedDerivativesPool(address(baseToken), address(tradeToken), address(s_tradeToken)); 
//         console.log('hello!'); 
    
//     }
//     function getERC() external view returns(address, address, address){
//         return(address(baseToken), address(tradeToken), address(s_tradeToken)); 
//     }
    // function setPool(address _pool) external{
    //     pool = _pool; 
    //     console.log('here??'); 
    // }

    // function deployNewPool() external{
    //     console.log('deploying'); 

    //     pool = new BoundedDerivativesPool(address(baseToken), address(tradeToken)); 
    //     console.log('deployed'); 

    // }


    // function testSwapStepDown() public {
    //     uint256 curPrice = PRECISION/2;//- pool.priceDelta()/10; 
    //     uint256 targetPrice = curPrice - pool.priceDelta(); 
    //     // curPrice -= pool.priceDelta()/10; 
    //     uint256 b = pool.getb(curPrice, false);
    //     uint256 a = pool.inv(pool.liquidity()); 
    //     uint256 s = pool.yInt(curPrice, b, a); 
    //     console.log('curPrice, targetPrice', curPrice, targetPrice);
    //     console.log('b,a', b,a);
    //     console.log('s', s); 

    //     (uint256 nextPrice, uint256 amountIn, uint256 amountOut, uint256 feeAmount) = 
    //         pool.swapStep(
    //         curPrice, targetPrice, PRECISION*100, 0, 
    //         a,s,b
    //         ); 

    //     console.log('nextprice,amountIn', nextPrice, amountIn); 
    //     console.log('amountOut', amountOut); 
    // }

    // function testSwapStepUp() public {
    //     uint256 curPrice = PRECISION/2+ 10* pool.priceDelta(); 
    //     uint256 targetPrice = curPrice + pool.priceDelta(); 
    //     curPrice += pool.priceDelta()/2; 
    //     uint256 b = pool.getb(curPrice, true);
    //     uint256 a = pool.inv(pool.liquidity()); 
    //     uint256 s = pool.yInt(curPrice, b, a); 
    //     console.log('curPrice, targetPrice', curPrice, targetPrice);
    //     console.log('b,a', b,a);
    //     console.log('s', s); 

    //     (uint256 nextPrice, uint256 amountIn, uint256 amountOut, uint256 feeAmount) = 
    //         pool.swapStep(
    //         curPrice, targetPrice, PRECISION*100, 0, 
    //         a,s,b
    //         ); 

    //     console.log('nextprice,amountIn', nextPrice, amountIn); 
    //     console.log('amountOut', amountOut); 
    // }

    // function testLoopSwapUp() public{


    //     pool.setPriceAndPoint( PRECISION/2); 
    //     // console.log('pool slot', pool.slot0().curPrice(), pool.slot0().point()); 

    //     bytes memory data; 
    //     (uint256 poolamountIn, uint256 poolamountOut) = pool.trade(
    //         address(this), 
    //         true, 
    //         10 * PRECISION, 
    //         PRECISION, 
    //         data
    //         ); 
    //     {
    //     uint256 b = pool.getb(PRECISION/2, true);
    //     uint256 a = pool.inv(pool.liquidity()); 
    //     uint256 s = pool.yInt(PRECISION/2, b, a); 
    //    (uint256 nextPrice, uint256 amountIn, uint256 amountOut, ) = 
    //         pool.swapStep(
    //         PRECISION/2, PRECISION, 10*PRECISION, 0, 
    //         a,s,b
    //         ); 
    //     console.log('nextprice', nextPrice, pool.getCurPrice() ); 
    //     console.log('tradetoken balance', tradeToken.balanceOf(address(this))); 
    //     console.log('amountIn/out', amountIn, amountOut); 
    //     console.log('pool amountIn/out', poolamountIn, poolamountOut);

    //     assert(nextPrice == pool.getCurPrice()); 
    //     assert(poolamountIn == amountIn && poolamountOut == amountOut);

    //     }

    // }
   // function testLoopSwapDown() public{

   //      pool.setPriceAndPoint( PRECISION/2 + 10 * pool.priceDelta()); 
   //      // console.log('pool slot', pool.slot0().curPrice(), pool.slot0().point()); 

   //      bytes memory data; 
   //      (uint256 poolamountIn, uint256 poolamountOut) = pool.trade(
   //          address(this), 
   //          false, 
   //          10 * PRECISION, 
   //          PRECISION, 
   //          data
   //          ); 
   //      console.log('poolamountIn/out', poolamountIn, poolamountOut); 
   //     //  {
   //     //  uint256 b = pool.getb(PRECISION/2 + 10 * pool.priceDelta(), true);
   //     //  uint256 a = pool.inv(pool.liquidity()); 
   //     //  uint256 s = pool.yInt(PRECISION/2 + 10 * pool.priceDelta(), b, a); 

   //     // (uint256 nextPrice, uint256 amountIn, uint256 amountOut, ) = 
   //     //      pool.swapStep(
   //     //      PRECISION/2 + 10 * pool.priceDelta(), 0, 10*PRECISION, 0, 
   //     //      a,s,b
   //     //      ); 
   //     //  console.log('nextprice', nextPrice, pool.getCurPrice() ); 
   //     //  console.log('tradetoken balance', tradeToken.balanceOf(address(this))); 
   //     //  console.log('amountIn/out', amountIn, amountOut); 
   //     //  console.log('pool amountIn/out', poolamountIn, poolamountOut);

   //     //  assert(nextPrice == pool.getCurPrice()); 
   //     //  assert(poolamountIn == amountIn && poolamountOut == amountOut);

   //     //  }

   //  }

   //  function testLiquidityProvisionSingle() public{
   //      uint256 priceA = PRECISION/2+ 5*pool.priceDelta(); 
   //      uint256 priceB = PRECISION/2 + 6* pool.priceDelta();
   //      uint16 pointLower = pool.priceToPoint(PRECISION/2 + 10*pool.priceDelta());
   //      uint16 pointUpper = pool.priceToPoint(PRECISION/2 + 11*pool.priceDelta()); 
   //      //selling, so placing asks with tradeAsset, 
   //      uint256 amount = 200 * PRECISION; //200 liquidity adding should equal 2 asks 
   //      bytes memory data; 
   //      console.log('basegiven', pool.baseGivenLiquidity(priceB, priceA, amount)); 
   //      (uint256 amount0, uint256 amount1) = pool.provide(
   //          address(this), 
   //          pointLower, pointUpper, uint128(amount), data);
   //      console.log('amounts', amount0, amount1); 
       
   //  }

   //  function testLiquidityProvision() public {
   //      // Provide liquidity(place asks) at 0.55-0.56
   //      testLiquidityProvisionSingle(); 

   //      //current price is 0.5 
   //      pool.setPriceAndPoint( PRECISION/2); 

   //      // buy up the curve 
   //      bytes memory data; 
   //      (uint256 poolamountIn, uint256 poolamountOut) = pool.trade(
   //          address(this), 
   //          true, 
   //          10 * PRECISION, 
   //          PRECISION, 
   //          data
   //      ); 

   //      console.log('price now', pool.getCurPrice());



   //  }

   //  function testLimitAsk() public {
   //      uint256 amount = 200 * PRECISION; //200 liquidity adding should equal 2 asks 
   //      pool.setPriceAndPoint( PRECISION/2); 

   //      uint256 multiplier = 3; 

   //      pool.placeLimitOrder(
   //          address(this), 55,uint128(amount*multiplier), true); 
   //      pool.placeLimitOrder(
   //          address(pool), 55, uint128(amount), true);
   //      pool.placeLimitOrder(
   //          address(this), 56,uint128(amount)*2, true); 
   //      pool.placeLimitOrder(
   //          address(this), 57,uint128(amount)*2, true); 
   //      pool.placeLimitOrder(
   //          address(this), 58,uint128(amount), true); 
   //      pool.placeLimitOrder(
   //          address(this), 59,uint128(amount), true); 

   //      console.log('onetime', pool.getOneTimeLiquidity(55, true) );

   //      // buy up the curve 
   //      bytes memory data; 
   //      (uint256 poolamountIn, uint256 poolamountOut) = pool.trade(
   //          address(this), 
   //          true, 
   //          10 * PRECISION, 
   //          PRECISION, 
   //          data
   //      ); 

   //      console.log('poolamountin', poolamountIn, poolamountOut); 

   //      //claim 
   //      uint256 claimAmount = pool.claimFilledOrder(
   //          address(this), 55, true);
   //      uint256 claimAmount2 = pool.claimFilledOrder(
   //          address(pool), 55, true);
   //      console.log('claimAmount', claimAmount, claimAmount2); 


   //      assert(isClose(claimAmount, claimAmount2*multiplier, 100)); 
   //  }

   //  function testLimitAskGoBackDown() public {
   //      // first go back down before filled

   //      uint256 amount = 200 * PRECISION; //200 liquidity adding should equal 2 asks 
   //      pool.setPriceAndPoint( PRECISION/2); 

   //      uint256 multiplier = 3; 

   //      pool.placeLimitOrder(
   //          address(this), 55,uint128(amount*multiplier), true); 
   //      pool.placeLimitOrder(
   //          address(pool), 55, uint128(amount), true);
        
   //      // buy up the curve 
   //      bytes memory data; 
   //      (uint256 poolamountIn, uint256 poolamountOut) = pool.trade(
   //          address(this), 
   //          true, 
   //          6*PRECISION, 
   //          PRECISION, 
   //          data
   //      ); 
   //      assert(pool.getOneTimeLiquidity( 55,  true) != 0 );
   //      assert(pool.getNumCross(55, true) == 0); 
   //      console.log('oneTimeLiquidity', pool.getOneTimeLiquidity(55, true), pool.getNumCross(55, true)); 
   //      console.log('price now', pool.getCurPrice());
   //      console.log('poolamountin', poolamountIn, poolamountOut); 

   //      //go back down
   //      ( poolamountIn,  poolamountOut) = pool.trade(
   //          address(this), 
   //          false, 
   //          7*PRECISION, 
   //          PRECISION, 
   //          data
   //      ); 
   //      console.log('poolamountinBefore', poolamountIn, poolamountOut); 

   //      // and go back up again
   //      ( poolamountIn,  poolamountOut) = pool.trade(
   //          address(this), 
   //          true, 
   //          5*PRECISION, 
   //          PRECISION, 
   //          data
   //      ); 
   //      console.log('poolamountin', poolamountIn, poolamountOut); 

   //      assert(pool.getNumCross(55, true) == 0); 
   //      assert(pool.getOneTimeLiquidity( 55,  true) != 0 );

   //      // go up now and fill the order
   //      ( poolamountIn,  poolamountOut) = pool.trade(
   //          address(this), 
   //          true, 
   //          1*PRECISION, 
   //          PRECISION, 
   //          data
   //      ); 
   //      uint256 claimAmount = pool.claimFilledOrder(
   //          address(this), 55, true);
   //      uint256 claimAmount2 = pool.claimFilledOrder(
   //          address(pool), 55, true);
   //      console.log('claimAmount', claimAmount, claimAmount2); 

   //      // and try to go back down again 
   //      ( poolamountIn,  poolamountOut) = pool.trade(
   //          address(this), 
   //          false, 
   //          7*PRECISION, 
   //          PRECISION, 
   //          data
   //      );         
   //      console.log('poolamountinNow', poolamountIn, poolamountOut); 
   //      console.log('oneTimeLiquidity', pool.getOneTimeLiquidity(55, true), pool.getNumCross(55, true)); 

   //  }

   //  function testLimitBid() public {
   //      uint256 amount = 200 * PRECISION; //200 liquidity adding should equal 2 asks 
   //      pool.setPriceAndPoint( PRECISION/2 + 10*pool.priceDelta() ); 

   //      uint256 multiplier = 2; 

   //      pool.placeLimitOrder(
   //          address(this), 58,uint128((amount*11)/4), false); 
   //      pool.placeLimitOrder(
   //          address(pool), 58, uint128(amount), false);
   //      pool.placeLimitOrder(
   //          address(this), 56,uint128(amount)*2, false); 

   //      console.log('onetime', pool.getOneTimeLiquidity(55, true) );

   //      // sell down the curve 
   //      bytes memory data; 
   //      (uint256 poolamountIn, uint256 poolamountOut) = pool.trade(
   //          address(this), 
   //          false, 
   //          10 * PRECISION, //this should be trade tokens, so 
   //          PRECISION, 
   //          data
   //      ); 

   //      console.log('poolamountin', poolamountIn, poolamountOut); 
   //      console.log('curprice', pool.getCurPrice() ); 

   //      //claim 
   //      assert(pool.positionIsFilled(address(this),58, false)); 
   //      uint256 claimAmount = pool.claimFilledOrder(
   //          address(this), 58, false);
   //      uint256 claimAmount2 = pool.claimFilledOrder(
   //          address(pool), 58, false);
   //      assert(!pool.positionIsFilled(address(this),58, false));

   //      console.log('claimAmount', claimAmount, claimAmount2); 

   //      //go up now 
   //      ( poolamountIn,  poolamountOut) = pool.trade(
   //          address(this), 
   //          true, 
   //          poolamountOut, //this should be base tokens, so 
   //          PRECISION, 
   //          data
   //      ); 

   //      console.log('poolamountin', poolamountIn, poolamountOut); 
   //      console.log('curprice should be higher than start', pool.getCurPrice() ); 

   //      // place order again
   //      pool.placeLimitOrder(
   //          address(this), 64,uint128((amount*11)/4), false); 
   //      pool.placeLimitOrder(
   //          address(pool), 64, uint128(amount), false);

   //      // go down but don't fill
   //      ( poolamountIn,  poolamountOut) = pool.trade(
   //          address(this), 
   //          false, 
   //          8 * PRECISION, //this should be trade tokens, so 
   //          PRECISION, 
   //          data
   //      ); 
   //      console.log('poolamountin', poolamountIn, poolamountOut); 
   //      assert(!pool.positionIsFilled(address(this),64, false));

   //      //go back up and see that it is not depleted 
   //      ( poolamountIn,  poolamountOut) = pool.trade(
   //          address(this), 
   //          true, 
   //          poolamountOut, //this should be trade tokens, so 
   //          PRECISION, 
   //          data
   //      ); 
   //      console.log('poolamountin', poolamountIn, poolamountOut); 
   //      console.log('curprice should be same as before', pool.getCurPrice() ); 



   //      //assert(isClose(claimAmount, claimAmount2*multiplier, 100));


   //  }
    // function mintAndApprove() external{
    //     pool.pool().setPriceAndPoint( PRECISION/2 + 10*pool.pool().priceDelta() );
    //     pool.BaseToken().mint(address(this), 100*PRECISION); 

    //     pool.BaseToken().approve(address(pool), 100*PRECISION); 
    // }

    // function testTakerOpenAndClose() external {
    //     bytes memory data; 

    //     (uint256 amountIn, uint256 amountOut ) = pool.takerOpen(false, int256(8* PRECISION), PRECISION, data );
    //     uint256 shorterCollateral =  amountIn.mulWadDown(pool.maxPrice()) - amountOut;
    //     console.log('amountIn transferred',shorterCollateral); 
    //     // console.log('s_tradebalance, amountIn', )
    //     console.log('balance of pool', baseToken.balanceOf(address(pool)), tradeToken.balanceOf(address(pool))); 

    //     // buy up again
    //     (amountIn, amountOut) = pool.takerOpen(true, int256(amountOut), PRECISION, data );
    //     uint256 longCollateral = amountIn; 
    //     console.log('shouldbesame', amountOut, s_tradeToken.balanceOf(address(this))); 
    //     assert(isClose(amountOut, s_tradeToken.balanceOf(address(this)) , 10000)); 

    //     console.log('balance of pool', baseToken.balanceOf(address(pool)), tradeToken.balanceOf(address(pool))); 

    //     // unwind process, first close short
    //     (amountIn, amountOut) = pool.takerClose(false, -int256(s_tradeToken.balanceOf(address(this))), PRECISION, data); 
    //     uint256 shortLoss = shorterCollateral - (amountOut.mulWadDown(pool.maxPrice()) - amountIn); 
    //     console.log('balance of pool', baseToken.balanceOf(address(pool)), tradeToken.balanceOf(address(pool))); 
    //     console.log('shorter loss',  shorterCollateral - (amountOut.mulWadDown(pool.maxPrice()) - amountIn)); 

    //     //then close long
    //     (amountIn, amountOut) = pool.takerClose(true, int256(tradeToken.balanceOf(address(this))), PRECISION, data); 
    //     console.log('balance of pool', baseToken.balanceOf(address(pool)), tradeToken.balanceOf(address(pool))); 
    //     console.log('my loss is your gain', amountOut - longCollateral, shortLoss); 
    //     assert(isClose(amountOut - longCollateral, shortLoss , 10000)); 
    // }

    // function testMaker() external {
    //     bytes memory data; 

    //     //maker shorts and taker longs 
    //     (uint256 escrowAmount, uint128 crossId) = pool.makerOpen(61, uint128(500*PRECISION), false); 
    //     console.log('escrowAmount', escrowAmount); 
    //     (uint256 amountIn, uint256 amountOut) = pool.takerOpen(true, int256(escrowAmount), PRECISION, data );
    //     console.log('amountin/out', amountIn, amountOut); 


    //     //maker longs and taker shorts 

    // }

    // function testMakerCloses() external{}
    // function testMultiple() external{}

    // function isClose(uint256 a, uint256 b, uint256 roundlimit) public pure returns(bool){

    //     return ( a <= b+roundlimit || a>= b-roundlimit); 
    // }


    // }

    // function testLimitBidAskMultiplePeople(){} 
    

//}