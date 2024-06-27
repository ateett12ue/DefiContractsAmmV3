// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;


contract CircuitBreaker {
    bool private stopped = false;
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier stopInEmergency() {
        require(!stopped, "Circuit breaker is active");
        _;
    }

    function toggleCircuitBreaker() public onlyOwner {
        stopped = !stopped;
    }

    function safeFunction() public stopInEmergency {
        // Function logic that should be stopped in emergency
    }
}
