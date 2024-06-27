// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract DataConsumer is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    uint256 public data;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    constructor() {
        setPublicChainlinkToken();
        oracle = 0x7AFe30cB3E53dba6801aa0EA647A0b028dD0140c; // Replace with the oracle address
        jobId = "b728d1650d9d45c486d1d6d3d4db4dcf"; // Replace with the job ID
        fee = 0.1 * 10 ** 18; // (Varies by network and job)
    }

    function requestData() public {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        request.add("get", "https://api.yourbackend.com/data"); // Your backend API endpoint
        request.add("path", "data"); // The path to the data in the JSON response
        sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, uint256 _data) public recordChainlinkFulfillment(_requestId) {
        data = _data;
    }
}
