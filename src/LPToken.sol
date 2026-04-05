// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LPToken {
    string public name = "AMM LP Token";
    string public symbol = "ALP";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public amm;

    mapping(address => uint256) public balanceOf;

    constructor() {
        amm = msg.sender; 
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == amm, "Only AMM can mint");
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == amm, "Only AMM can burn");
        require(balanceOf[from] >= amount, "Insufficient LP balance");
        totalSupply -= amount;
        balanceOf[from] -= amount;
    }
}