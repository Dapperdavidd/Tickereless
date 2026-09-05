// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { DemoToken } from "./DemoToken.sol";

/// @notice Test-only payment token with a one-time self-service allocation.
contract DemoPaymentToken is DemoToken {
    uint256 public constant FAUCET_AMOUNT = 1_000e6;

    mapping(address => bool) public claimed;

    error AlreadyClaimed();

    event FaucetClaimed(address indexed recipient, uint256 amount);

    constructor() DemoToken("Test USD Coin", "tUSDC", 6) { }

    function claim() external {
        if (claimed[msg.sender]) revert AlreadyClaimed();
        claimed[msg.sender] = true;
        _mint(msg.sender, FAUCET_AMOUNT);
        emit FaucetClaimed(msg.sender, FAUCET_AMOUNT);
    }
}
