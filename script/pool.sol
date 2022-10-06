// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
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
    function testMakerCloseLong() internal{
   //  	console.log("====NEW FUNCTION====="); 
   //      bytes memory data; 

   //  	uint256 tradeBalance = tradeToken.balanceOf(address(this)); 
   //  	bool takerOpenLong = true; 
   //      uint16 point = 60; 
   //      uint256 tradebalanceToLiq = pool.pool().liquidityGivenTrade(pool.pool().pointToPrice(point+1), pool.pool().pointToPrice(point), tradeBalance); 

   //  	// assumes prvious function has been run 
   //      (uint256 escrowAmount, uint128 crossId) = pool.makerClose(point, uint128(tradebalanceToLiq), true); 
   //      console.log('escrowAmount in trade', escrowAmount, tradeBalance); 
 		// uint256 amountIn; 
 		// uint256 amountOut;
   //      // either a takerlongopen or a takerclose short can fill, start with taker open long
   //      if (takerOpenLong){
   //      	(amountIn, amountOut) = pool.takerOpen(true, -int256(tradeBalance), PRECISION, data); 
   //      	console.log('amountin/out', amountIn, amountOut);
   //      	assert(isClose(tradeBalance, tradeToken.balanceOf(address(this)), 10000 )); 
   //      	console.log('balance of pool base', baseToken.balanceOf(address(pool))); 
   //      	console.log('curprice', pool.pool().getCurPrice()); 

   //      	//after claiming, balance of pool base should roughly equal 0 

   //      }
   //      // try with taker close short 
   //      else{
   //      	// create new bid 
   //      	(uint256 escrowAmount, uint128 crossId) = pool.makerOpen(point, makerbids, true); 
   //      	// open short

   //      	// close short into above maker closelong

   //      }

    }
    function testMakerCloseShort() internal{}

    function testMultiple() external{
    	
    }
    function testNoLiquidityTeleport() internal{}

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


    function isClose(uint256 a, uint256 b, uint256 roundlimit) public pure returns(bool){

        return ( a <= b+roundlimit || a>= b-roundlimit); 
    }

    function run() public {
    	mintAndApprove(); 
    	testMakerLongAndTakerShorts();
    	testMakerCloseLong();  
        vm.broadcast();
    }
}
