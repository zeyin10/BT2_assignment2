// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken public token;
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        token = new MyToken();
    }

    // --- UNIT TESTS ---
    function test_InitialSupply() public view { 
        assertEq(token.totalSupply(), 1000000 * 10**18); 
    }

    function test_Mint() public { 
        token.mint(alice, 100); 
        assertEq(token.balanceOf(alice), 100); 
    }

    function test_Transfer() public { 
        token.transfer(alice, 500); 
        assertEq(token.balanceOf(alice), 500); 
    }

    function test_Approve() public { 
        token.approve(alice, 1000); 
        assertEq(token.allowance(address(this), alice), 1000); 
    }

    function test_TransferFrom() public {
        token.approve(address(this), 1000);
        token.transferFrom(address(this), bob, 500);
        assertEq(token.balanceOf(bob), 500);
    }

    // ИСПРАВЛЕННЫЙ ТЕСТ НА ОШИБКУ (Requirement 9)
    function test_RevertWhen_InsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert("Not enough balance");
        token.transfer(bob, 1); 
    }

    function test_BalanceAfterTransfer() public {
        uint256 startBalance = token.balanceOf(address(this));
        token.transfer(alice, 100);
        assertEq(token.balanceOf(address(this)), startBalance - 100);
    }

    function test_TransferZeroAmount() public { 
        bool success = token.transfer(alice, 0); 
        assertTrue(success); 
    }

    function test_ApproveOverwrite() public {
        token.approve(alice, 100);
        token.approve(alice, 200);
        assertEq(token.allowance(address(this), alice), 200);
    }

    function test_TransferToSelf() public {
        uint256 bal = token.balanceOf(address(this));
        token.transfer(address(this), 100);
        assertEq(token.balanceOf(address(this)), bal);
    }

    // --- FUZZ TESTING (Requirement 10) ---
    function testFuzz_Transfer(uint256 amount) public {
        uint256 myBalance = token.balanceOf(address(this));
        amount = bound(amount, 0, myBalance); 

        token.transfer(alice, amount);
        assertEq(token.balanceOf(alice), amount);
    }

    // --- INVARIANT TESTING (Requirement 11) ---
    function testInvariant_TotalSupplyNeverChanges() public view {
        assertEq(token.totalSupply(), 1000000 * 10**18);
    }
}