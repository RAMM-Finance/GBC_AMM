// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
// import "../src/GBC.sol";
import "../src/GBC.sol"; 
import "../src/libraries.sol"; 
import "forge-std/console.sol";
contract Pool is Script {
    using FixedPointMath for uint256;
    uint256 constant PRECISION = 1e18; 
    BoundedDerivativesPool pool; 
    ERC20 baseToken; 
    ERC20 tradeToken; 
    ERC20 s_tradeToken; 
    uint256 constant ROUND = 1e4; 
    function setUp() public {
        baseToken = new ERC20( "base",
        "base",
        18);
        tradeToken = new ERC20( "trade",
        "trade",
        18); 
        s_tradeToken = new ERC20("strade", "strade", 18); 

        pool = new BoundedDerivativesPool(address(baseToken), address(tradeToken), address(s_tradeToken)); 
    }

    function mintAndApprove() internal{
        pool.pool().setPriceAndPoint( PRECISION/2 + 10*pool.pool().priceDelta() );
        pool.BaseToken().mint(address(this), 100*PRECISION); 

        pool.BaseToken().approve(address(pool), 100*PRECISION);
    }
    function testMakerShortAndTakerLongs() internal {
        // bytes memory data; 
        // // pool.pool().setLiquidity(uint128(100*PRECISION)); 
        // //maker shorts and taker longs 
        // (uint256 escrowAmount, uint128 crossId) = pool.makerOpen(62, uint128(500*PRECISION), false); 
        // console.log('escrowAmount', escrowAmount); 
        // (uint256 amountIn, uint256 amountOut) = pool.takerOpen(true,  int256(6*PRECISION ), PRECISION, data );
        // console.log('amountin/out', amountIn, amountOut); 

        // // maker can claim and again 
        // pool.makerClaimOpen(62, false); 
        // uint256 prevBalance = s_tradeToken.balanceOf(address(this));
        // console.log('balances', prevBalance, amountOut); 
        // pool.makerClaimOpen(62, false); 
        // assert (s_tradeToken.balanceOf(address(this)) == prevBalance); 


    }
    function testMakerLongAndTakerShorts() internal{
  //       bytes memory data; 
  //       uint128 initialLiq = 0; 
  //       uint16 point = 59; 
  //       uint128 makerbids = uint128(500*PRECISION); 

  //       pool.pool().setLiquidity(initialLiq); 
		// // assert(pool.pool().liquidityGivenBase()==  )

  //       (uint256 escrowAmount, uint128 crossId) = pool.makerOpen(point, makerbids, true); 
  //       pool.makerOpen(point-1, makerbids, true); 

  //       uint256 liq = pool.pool().liquidityGivenBase(
  //       	pool.pool().pointToPrice(point+1), pool.pool().pointToPrice(point), escrowAmount
  //       	);
  //       console.log('equal',liq , makerbids); 
  //       console.log('escrowAmount', escrowAmount); 
  //       assert(isClose(liq, makerbids, 10000)); 

  //       (uint256 amountIn, uint256 amountOut) = pool.takerOpen(false,int256(uint256(makerbids*2/100)), PRECISION, data); 
  //       assert(isClose(s_tradeToken.balanceOf(address(this)), uint256(makerbids/100), 10000)); 
  //       console.log('amountin/out', amountIn, amountOut); 
		// pool.takerOpen(false,10000, PRECISION/2, data); 
  //       console.log('curprice', pool.pool().getCurPrice()); 

  //       pool.makerClaimOpen(point, true); 
  //       uint256 prevBalance = tradeToken.balanceOf(address(this)); 
  //       assert(isClose(prevBalance, uint256(makerbids/100), 10000)); 
  //       pool.makerClaimOpen(point, true); 
		// assert(tradeToken.balanceOf(address(this)) == prevBalance); 

		// pool.makerClaimOpen(point-1, true);
  //       assert(isClose(tradeToken.balanceOf(address(this)), prevBalance*2, 10000)); 

    }
    function testWithdrawPartiallyFilled() internal{
        bytes memory data; 
        pool.pool().setLiquidity(0);
        uint256 randomamount = 23;

        tradeToken.mint(address(this), (randomamount * PRECISION/3)); 
    	uint256 tradeBalance = tradeToken.balanceOf(address(this)); 
        uint16 point = 61; 
        uint256 tradebalanceToLiq = pool.pool().liquidityGivenTrade(pool.pool().pointToPrice(point+1), pool.pool().pointToPrice(point), tradeBalance); 

        // Place long close asks
        (uint256 escrowAmount, uint128 crossId) = pool.makerClose(point, tradeBalance, true); 
        console.log('escrowAmount in trade', escrowAmount, crossId); 

        (uint256 amountIn,uint256 amountOut) = pool.takerOpen(true, -int256(tradeBalance/2), PRECISION, data); 
        assert(isClose(amountOut, tradeBalance/2, 1)); 
        assert(amountOut == tradeToken.balanceOf(address(this))); 
        assert(isClose(tradeBalance/2, tradeToken.balanceOf(address(this)), ROUND )); 


        // get base tokens and trade back 
       	(uint256 baseAmount, uint256 tradeAmount) = pool.makerPartiallyClaim(point, true, false); 
       	assert(isClose(tradeAmount, tradeBalance/2, ROUND )); 

       	// try to buy again
        //pool.takerOpen(true, -int256(tradeBalance/2), PRECISION, data); 
        // (uint256 baseAmount, uint256 tradeAmount ) = pool.makerPartiallyClaim(point, true, false); 
       	// pool.pool().liquid

    }
    function testMakerCloseLong() internal{
    	console.log("====NEW FUNCTION====="); 
        bytes memory data; 
        pool.pool().setLiquidity(0);
        tradeToken.mint(address(this), (23 * PRECISION/3)); 
    	uint256 tradeBalance = tradeToken.balanceOf(address(this)); 
    	bool takerOpenLong = true; 
        uint16 point = 61; 
        uint256 tradebalanceToLiq = pool.pool().liquidityGivenTrade(pool.pool().pointToPrice(point+1), pool.pool().pointToPrice(point), tradeBalance); 

    	// assumes prvious function has been run 
        (uint256 escrowAmount, uint128 crossId) = pool.makerClose(point, tradeBalance, true); 
        console.log('escrowAmount in trade', escrowAmount, crossId); 
 		uint256 amountIn; 
 		uint256 amountOut;
        // either a takerlongopen or a takerclose short can fill, start with taker open long
        if (takerOpenLong){
        	(amountIn, amountOut) = pool.takerOpen(true, -int256(tradeBalance), PRECISION, data); 
        	console.log('amountin/out', amountIn, amountOut);
        	assert(isClose(tradeBalance, tradeToken.balanceOf(address(this)), 10000 )); 
        	console.log('balance of pool base', baseToken.balanceOf(address(pool)), tradeToken.balanceOf(address(pool))); 
        	console.log('curprice', pool.pool().getCurPrice()); 

        	//after claiming, balance of pool base should roughly equal 0 
        	pool.makerClaimClose( point, true);
        	// pool.makerPartiallyClaim( point, true, false); 
   
        	assert(isClose(amountIn, baseToken.balanceOf(address(this)), 10000)); 

        }
        // try with taker close short 
        else{
        	// create new bid 
        	// (uint256 escrowAmount, uint128 crossId) = pool.makerOpen(point, makerbids, true); 
        	// open short

        	// close short into above maker closelong

        }

    }

    // TODO rounding error below 
    function testMakerCloseShort() internal{
     	bytes memory data; 
        pool.pool().setLiquidity(0);
        s_tradeToken.mint(address(this), (23 * PRECISION/3)); 
    	uint256 tradeBalance = s_tradeToken.balanceOf(address(this)); 
    	bool takerOpenLong = true; 
        uint16 point = 59; 

        (uint256 escrowAmount, uint128 crossId) = pool.makerClose(point, tradeBalance, false); 
        console.log('escrowAmount in trade', escrowAmount, crossId); 
       	uint256 amountIn; 
 		uint256 amountOut;

       	(amountIn, amountOut) = pool.takerOpen(false, int256(tradeBalance+100), PRECISION, data); 
       	assert(isClose(amountOut, escrowAmount, ROUND));
        console.log('balance of pool base', baseToken.balanceOf(address(pool)), tradeToken.balanceOf(address(pool))); 
        	console.log('curprice', pool.pool().getCurPrice()); 

        // //ok, so this thing is stuck
        // (uint256 baseAmount, uint256 tradeAmount) = pool.makerPartiallyClaim(point, false, false); 
        // assert(isClose(baseAmount))

       	uint256 claimedAmount = pool.makerClaimClose(point, false); 
       	assert(isClose(claimedAmount + amountOut,  amountIn, ROUND)); 
        console.log('balance of pool base', baseToken.balanceOf(address(pool)), tradeToken.balanceOf(address(pool))); 
    }

    function testMultipleMakerTaker() external{
    	// point 58 59 bids
    	// point 61 62 asks 
    	// go up and down back and forth 
    }
    function testMakerPartiallyClaimCloseShort() internal{}
    function testNoLiquidityTeleport() internal{}
    function testLiquidityProvision() internal{}
  	function testReduceOrder()internal{}

  //   function testMakerRemoveLiqBeforeBoundary()internal{
  //       bytes memory data; 
  //       uint128 initialLiq = 0; 
  //       uint16 point = 59; 
  //       uint128 makerbids = uint128(500*PRECISION); 
  //       pool.pool().setLiquidity(initialLiq); 

  //       (uint256 escrowAmount, uint128 crossId) = pool.makerOpen(point, makerbids, true); 
  //       uint256 liq = pool.pool().liquidityGivenBase(
  //       	pool.pool().pointToPrice(point+1), pool.pool().pointToPrice(point), escrowAmount
  //       	);
  //       console.log('equal',liq , makerbids); 
  //       console.log('escrowAmount', escrowAmount); 
  //       assert(isClose(liq, makerbids, 10000)); 

  //       (uint256 amountIn, uint256 amountOut) = pool.takerOpen(false,int256(uint256(makerbids/100)), PRECISION, data); 
  //       assert(isClose(s_tradeToken.balanceOf(address(this)), uint256(makerbids/100), 10000)); 
  //       console.log('amountin/out', amountIn, amountOut); 
		// pool.takerOpen(false,10000, PRECISION/2, data); 
  //       console.log('curprice', pool.pool().getCurPrice()); 


  //   }
 	function takerLongAndShort() internal{
  		bytes memory data; 
  		// uint256 initialLiq = 100; 
  		// pool.pool().setLiquidity(initialLiq * PRECISION); 

		console.log('---balances---',s_tradeToken.balanceOf(address(this)), tradeToken.balanceOf(address(this)), 
 			baseToken.balanceOf(address(this))); 
 		pool.takerOpen(true,  -int256(5* PRECISION), PRECISION, data); 
 		pool.takerOpen(false,  int256(3* PRECISION), PRECISION, data); 

 		console.log('price', pool.pool().getCurPrice()); 
		console.log('---balances---',s_tradeToken.balanceOf(address(this)), tradeToken.balanceOf(address(this)), 
 			baseToken.balanceOf(address(this)));
 		// assert(tradeToken.balanceOf(address(this)) - s_tradeToken.balanceOf(address(this)) ==  )

 		pool.takerClose(true, int256(5* PRECISION), PRECISION, data); 
 		pool.takerClose(false, -int256(3* PRECISION), PRECISION, data);
 		console.log('price', pool.pool().getCurPrice()); 
 		console.log('---balances---',s_tradeToken.balanceOf(address(this)), tradeToken.balanceOf(address(this)), 
 			baseToken.balanceOf(address(this))); 
 		assert(s_tradeToken.balanceOf(address(this)) == 0); 
 		assert(tradeToken.balanceOf(address(this))==0); 
 		// assert(baseToken.balanceOf(address(this))==0); 
 	}

  	function testConsistentMaker() internal{
  		uint256 managerCount = 10; 
  		bytes memory data; 
  		uint256 in_; 
  		uint256 out_; 

		uint256 totalamounts; 
		uint256 totalCollateral; 
		uint256 pricenow; 
		uint256 priceafter; 
  		uint256[] memory amounts = new uint[](managerCount);
		amounts[0] = 13;
		amounts[1] = 15;
		amounts[2] = 23;
		amounts[3] = 9;
		amounts[4] = 3;
		amounts[5] = 53;
		amounts[6] = 23;
		amounts[7] = 39;
		amounts[8] = 5;
		amounts[9] = 15;

  		// get a whole bunch a managers and let them buy up one at a time 
  		// for(uint256 i; i<managerCount; i++){
  		// 	totalamounts += amounts[i]; 
  		// 	console.log('new trader and current price----:' , pool.pool().getCurPrice()); 
  		// 	pricenow = pool.pool().getCurPrice(); 
  		// 	(in_,out_) = pool.takerOpen(true,  -int256(amounts[i] * PRECISION/10), PRECISION, data); 
  		// 	priceafter = pool.pool().getCurPrice();  
  		// 	totalCollateral += in_; 
  		// 	assert( isClose((priceafter-pricenow)* amounts[i] * PRECISION/10, in_, ROUND/10)); 
  		// }
  		// assert( isClose(pool.pool().areaUnderCurve(0,totalamounts, PRECISION/100, (6*PRECISION/10) ), totalCollateral, ROUND  ) ); 
  		// get a whole bunch of managers and some buy some takershort
  		pricenow = pool.pool().getCurPrice(); 
  		for(uint256 i; i< managerCount; i++){

  			(in_,out_) = i%3 ==0 ? pool.takerOpen(false,  int256(amounts[i] * PRECISION/10), PRECISION, data)
  			 			:pool.takerOpen(true,  -int256(amounts[i] * PRECISION/10), PRECISION, data);

  		}
  		//unwind everything
  		for(uint256 i; i< managerCount; i++){
  			console.log('i', i); 
  			(in_, out_) = i%3 ==0 ? pool.takerClose(false, -int256(amounts[i] * PRECISION/10), PRECISION, data)
  							: pool.takerClose(true, int256(amounts[i] * PRECISION/10), PRECISION, data); 
  		}
  		priceafter = pool.pool().getCurPrice(); 
  		console.log('prices', priceafter, pricenow); 


  		// get a whole bunch of managers and some taker buy some taker short some set limits 

  		//everyone can claim + unwind 


  	}
    function isClose(uint256 a, uint256 b, uint256 roundlimit) public pure returns(bool){

        return ( a <= b+roundlimit || a>= b-roundlimit); 
    }

    function run() public {
    	mintAndApprove(); 
    	// testMakerLongAndTakerShorts();
    	// testWithdrawPartiallyFilled(); 
    	// testMakerCloseLong();  
    	//testMakerCloseShort(); 
   		 testConsistentMaker();
   		//takerLongAndShort(); 
        vm.broadcast();
    }
  //     	struct TestVars1{
  // 		uint256 in_; 
  // 		uint256 out_; 

		// uint256 totalamounts; 
		// uint256 totalCollateral; 
		// uint256 pricenow; 
		// uint256 priceafter;   		
  // 	}
}
