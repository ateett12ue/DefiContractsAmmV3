// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TreasuryManagement is Ownable {
    struct TokenInfo {
        IERC20 token;
        uint256 unlockedBalance;
        uint256 lockedBalance;
        uint256 unlockTime;
    }

    mapping(address => TokenInfo) public tokenInfo;
    address[] public tokens;
    uint256 public tokenCount;

    event Deposit(address indexed user, address token, uint256 amount);
    event Withdraw(address indexed user, address token, uint256 amount);
    event Lock(address indexed user, address token, uint256 amount, uint256 time);
    event Unlock(address indexed user, address token, uint256 amount);

    constructor() {
        tokenCount = 0;
    }

    function addToken(address tokenAddress) external onlyOwner {
        require(tokenCount < 8, "Cannot add more than 8 tokens");
        tokens.push(tokenAddress);
        tokenInfo[tokenAddress] = TokenInfo({
            token: IERC20(tokenAddress),
            unlockedBalance: 0,
            lockedBalance: 0,
            unlockTime: 0
        });
        tokenCount++;
    }

    function deposit(address tokenAddress, uint256 amount) external {
        require(tokenInfo[tokenAddress].token != IERC20(address(0)), "Token not supported");
        require(tokenInfo[tokenAddress].token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 lockedAmount = (amount * 90) / 100;
        uint256 unlockedAmount = amount - lockedAmount;

        tokenInfo[tokenAddress].unlockedBalance += unlockedAmount;
        tokenInfo[tokenAddress].lockedBalance += lockedAmount;
        tokenInfo[tokenAddress].unlockTime = block.timestamp + 30 days;  // Example lock period

        emit Deposit(msg.sender, tokenAddress, amount);
    }

    function withdraw(address tokenAddress, uint256 amount) external {
        require(tokenInfo[tokenAddress].token != IERC20(address(0)), "Token not supported");
        require(tokenInfo[tokenAddress].unlockedBalance >= amount, "Insufficient unlocked balance");

        tokenInfo[tokenAddress].unlockedBalance -= amount;
        require(tokenInfo[tokenAddress].token.transfer(msg.sender, amount), "Transfer failed");
        emit Withdraw(msg.sender, tokenAddress, amount);
    }

    function lockFunds(address tokenAddress, uint256 amount, uint256 time) external onlyOwner {
        require(tokenInfo[tokenAddress].token != IERC20(address(0)), "Token not supported");
        require(tokenInfo[tokenAddress].unlockedBalance >= amount, "Insufficient unlocked balance to lock");

        tokenInfo[tokenAddress].unlockedBalance -= amount;
        tokenInfo[tokenAddress].lockedBalance += amount;
        tokenInfo[tokenAddress].unlockTime = block.timestamp + time;
        emit Lock(msg.sender, tokenAddress, amount, time);
    }

    function unlockFunds(address tokenAddress) external {
        require(tokenInfo[tokenAddress].token != IERC20(address(0)), "Token not supported");
        require(block.timestamp >= tokenInfo[tokenAddress].unlockTime, "Funds are still locked");

        uint256 unlockedAmount = tokenInfo[tokenAddress].lockedBalance;
        tokenInfo[tokenAddress].unlockedBalance += unlockedAmount;
        tokenInfo[tokenAddress].lockedBalance = 0;
        emit Unlock(msg.sender, tokenAddress, unlockedAmount);
    }
}
