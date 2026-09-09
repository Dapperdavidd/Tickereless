// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { DemoToken } from "../src/DemoToken.sol";
import { TickerlessMarket } from "../src/TickerlessMarket.sol";

interface VmAddAsset {
    function startBroadcast() external;
    function stopBroadcast() external;
}

/// @notice Adds Microsoft to the existing Base Sepolia market without
/// replacing the market or disturbing the four live demo-equity inventories.
contract AddMicrosoftAsset {
    uint256 private constant BASE_SEPOLIA_CHAIN_ID = 84532;
    address private constant MARKET = 0xd747A01CD827Ff9ad69d5D8eaaf774aAF2695C9a;
    VmAddAsset private constant vm =
        VmAddAsset(address(uint160(uint256(keccak256("hevm cheat code")))));

    error UnsupportedChain(uint256 chainId);

    function run() external returns (DemoToken microsoft) {
        if (block.chainid != BASE_SEPOLIA_CHAIN_ID) revert UnsupportedChain(block.chainid);
        vm.startBroadcast();
        microsoft = new DemoToken("Demo Microsoft", "tMSFTc", 18);
        TickerlessMarket(MARKET).setAssetPrice(address(microsoft), 430.2e6);
        microsoft.mint(MARKET, 1_000e18);
        vm.stopBroadcast();
    }
}
