// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract ForkTest is Test {
    // Адреса в Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function setUp() public {
        vm.createSelectFork("https://eth.drpc.org", 19580000);
    }

    function test_ReadUSDCTotalSupply() public view {
        uint256 total = IERC20(USDC).totalSupply();
        console.log("Real USDC Total Supply:", total);
        assert(total > 0);
    }

    function test_SimulateUniswapSwap() public view {
        uint256 amountIn = 1 ether; // 1 ETH
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        uint256[] memory amountsOut = IUniswapV2Router(UNISWAP_ROUTER).getAmountsOut(amountIn, path);
        
        console.log("For 1 ETH you will get USDC:", amountsOut[1] / 1e6);
        assert(amountsOut[1] > 0);
    }
}