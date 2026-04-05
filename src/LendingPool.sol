// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MyToken.sol";

contract LendingPool {
    MyToken public collateralToken;
    MyToken public borrowToken;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public loans;
    
    // Константы из задания
    uint256 public constant LTV = 75; // 75% [cite: 65]
    uint256 public constant LIQUIDATION_THRESHOLD = 80; 

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Liquidated(address indexed user, address indexed liquidator, uint256 amount);

    constructor(address _collateral, address _borrow) {
        collateralToken = MyToken(_collateral);
        borrowToken = MyToken(_borrow);
    }

    function deposit(uint256 amount) external {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        uint256 maxBorrow = (deposits[msg.sender] * LTV) / 100;
        require(loans[msg.sender] + amount <= maxBorrow, "Exceeds LTV");

        loans[msg.sender] += amount;
        borrowToken.transfer(msg.sender, amount);
        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        borrowToken.transferFrom(msg.sender, address(this), amount);
        loans[msg.sender] -= amount;
        emit Repaid(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Not enough collateral");
        
        uint256 remainingCollateral = deposits[msg.sender] - amount;
        if (loans[msg.sender] > 0) {
            uint256 healthFactor = (remainingCollateral * LTV) / loans[msg.sender];
            require(healthFactor >= 100, "Health factor too low");
        }

        deposits[msg.sender] -= amount;
        collateralToken.transfer(msg.sender, amount);
    }

    function liquidate(address user, uint256 repayAmount) external {
        uint256 healthFactor = (deposits[user] * LIQUIDATION_THRESHOLD) / loans[user];
        require(healthFactor < 100, "User is safe");

        borrowToken.transferFrom(msg.sender, address(this), repayAmount);
        
        uint256 collateralToTake = repayAmount; 
        deposits[user] -= collateralToTake;
        loans[user] -= repayAmount;

        collateralToken.transfer(msg.sender, collateralToTake);
        emit Liquidated(user, msg.sender, repayAmount);
    }
}