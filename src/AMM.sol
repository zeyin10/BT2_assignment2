// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MyToken.sol";
import "./LPToken.sol";

contract AMM {
    MyToken public tokenX;
    MyToken public tokenY;
    LPToken public lpToken;

    uint256 public reserveX;
    uint256 public reserveY;

    // Events (Requirement 38)
    event LiquidityAdded(address indexed user, uint256 amountX, uint256 amountY, uint256 lpMinted);
    event LiquidityRemoved(address indexed user, uint256 amountX, uint256 amountY, uint256 lpBurned);
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut, bool isXtoY);

    constructor(address _tokenX, address _tokenY) {
        tokenX = MyToken(_tokenX);
        tokenY = MyToken(_tokenY);
        lpToken = new LPToken(); // AMM сам создает свой LP токен
    }

    // 1. Add Liquidity (Requirement 34)
    function addLiquidity(uint256 amountX, uint256 amountY) external returns (uint256) {
        tokenX.transferFrom(msg.sender, address(this), amountX);
        tokenY.transferFrom(msg.sender, address(this), amountY);

        uint256 lpToMint = amountX + amountY; // Simple LP calculation
        
        reserveX += amountX;
        reserveY += amountY;

        lpToken.mint(msg.sender, lpToMint);
        emit LiquidityAdded(msg.sender, amountX, amountY, lpToMint);
        return lpToMint;
    }

    // 2. Remove Liquidity (Requirement 35)
    function removeLiquidity(uint256 lpAmount) external {
        uint256 totalLP = lpToken.totalSupply();
        uint256 dx = (lpAmount * reserveX) / totalLP;
        uint256 dy = (lpAmount * reserveY) / totalLP;

        lpToken.burn(msg.sender, lpAmount);
        
        reserveX -= dx;
        reserveY -= dy;

        tokenX.transfer(msg.sender, dx);
        tokenY.transfer(msg.sender, dy);

        emit LiquidityRemoved(msg.sender, dx, dy, lpAmount);
    }

    // 3. Swap with 0.3% Fee & Slippage (Requirement 36, 39)
    function swap(uint256 amountIn, bool isXtoY, uint256 minAmountOut) external returns (uint256) {
        // Fee calculation: 99.7% of input is used for swap [cite: 36]
        uint256 amountInWithFee = (amountIn * 997) / 1000;
        uint256 amountOut = getAmountOut(amountInWithFee, isXtoY);

        require(amountOut >= minAmountOut, "Slippage too high"); // [cite: 39]

        if (isXtoY) {
            tokenX.transferFrom(msg.sender, address(this), amountIn);
            tokenY.transfer(msg.sender, amountOut);
            reserveX += amountIn;
            reserveY -= amountOut;
        } else {
            tokenY.transferFrom(msg.sender, address(this), amountIn);
            tokenX.transfer(msg.sender, amountOut);
            reserveY += amountIn;
            reserveX -= amountOut;
        }

        emit Swap(msg.sender, amountIn, amountOut, isXtoY);
        return amountOut;
    }

    // 4. Mathematical Formula (Requirement 37)
    // dy = (y * dx) / (x + dx)
    function getAmountOut(uint256 amountIn, bool isXtoY) public view returns (uint256) {
        if (isXtoY) {
            return (reserveY * amountIn) / (reserveX + amountIn);
        } else {
            return (reserveX * amountIn) / (reserveY + amountIn);
        }
    }
}