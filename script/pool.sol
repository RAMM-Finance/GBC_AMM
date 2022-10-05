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
    function testMaker() internal {
        bytes memory data; 

        //maker shorts and taker longs 
        (uint256 escrowAmount, uint128 crossId) = pool.makerOpen(61, uint128(500*PRECISION), false); 
        console.log('escrowAmount', escrowAmount); 
        (uint256 amountIn, uint256 amountOut) = pool.takerOpen(true, int256(escrowAmount), PRECISION, data );
        console.log('amountin/out', amountIn, amountOut); 

        //maker longs and taker shorts 

    }
    function testMakerCloses() external{}
    function testMultiple() external{}

    function isClose(uint256 a, uint256 b, uint256 roundlimit) public pure returns(bool){

        return ( a <= b+roundlimit || a>= b-roundlimit); 
    }

    function run() public {
    	mintAndApprove(); 
    	testMaker(); 
        vm.broadcast();
    }
}
