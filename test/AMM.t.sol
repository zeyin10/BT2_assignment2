// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "../src/MyToken.sol";
import "../src/LPToken.sol";

contract AMMTest is Test {
    AMM amm;
    MyToken tokenX;
    MyToken tokenY;
    address user = address(0x123);

    function setUp() public {
        tokenX = new MyToken();
        tokenY = new MyToken();
        // Деплоим AMM
        amm = new AMM(address(tokenX), address(tokenY));

        // Раздаем токены пользователю
        tokenX.mint(user, 1000 ether);
        tokenY.mint(user, 1000 ether);
        
        vm.startPrank(user);
        tokenX.approve(address(amm), 1000 ether);
        tokenY.approve(address(amm), 1000 ether);
        
        // 1. Test for adding liquidity (Requirement 34, 41)
        amm.addLiquidity(100 ether, 100 ether);
        vm.stopPrank();
    }

    function test_SwapWithFeeAndSlippage() public {
        vm.startPrank(user);
        uint256 amountIn = 10 ether;
        
        uint256 amountInWithFee = (amountIn * 997) / 1000;
        uint256 expectedOut = amm.getAmountOut(amountInWithFee, true);
        
        uint256 actualOut = amm.swap(amountIn, true, expectedOut);
        
        assertEq(actualOut, expectedOut);
        console.log("Tokens received (after 0.3% fee):", actualOut);
        vm.stopPrank();
    }

    function test_RemoveLiquidity() public {
        vm.startPrank(user);
        uint256 lpBalance = LPToken(amm.lpToken()).balanceOf(user);
        
        amm.removeLiquidity(lpBalance);
        
        assertEq(LPToken(amm.lpToken()).balanceOf(user), 0);
        console.log("Liquidity removed successfully");
        vm.stopPrank();
    }

    function test_SlippageProtection() public {
        vm.startPrank(user);
        uint256 amountIn = 10 ether;
        uint256 tooHighMinOut = 20 ether; 
        
        vm.expectRevert("Slippage too high");
        amm.swap(amountIn, true, tooHighMinOut);
        vm.stopPrank();
    }
}