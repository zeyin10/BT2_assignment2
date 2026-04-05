// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LendingPool.sol";
import "../src/MyToken.sol";

contract LendingPoolTest is Test {
    LendingPool pool;
    MyToken collateral;
    MyToken borrowToken;
    address user = address(0xABC);

    function setUp() public {
        collateral = new MyToken();
        borrowToken = new MyToken();
        pool = new LendingPool(address(collateral), address(borrowToken));

        collateral.mint(user, 1000 ether);
        borrowToken.mint(address(pool), 1000 ether); // Наполняем пул для займов

        vm.startPrank(user);
        collateral.approve(address(pool), 1000 ether);
        vm.stopPrank();
    }

    function test_DepositAndBorrow() public {
        vm.startPrank(user);
        pool.deposit(100 ether);
        
        // Пытаемся взять 75 (норма)
        pool.borrow(75 ether);
        assertEq(pool.loans(user), 75 ether);
        vm.stopPrank();
    }

    function test_FailExceedLTV() public {
        vm.startPrank(user);
        pool.deposit(100 ether);
        
        // Пытаемся взять 80 (больше 75% LTV) - должно упасть [cite: 73]
        vm.expectRevert("Exceeds LTV");
        pool.borrow(80 ether);
        vm.stopPrank();
    }
}