// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { DemoToken } from "../src/DemoToken.sol";
import { IERC20 } from "../src/IERC20.sol";
import { TickerlessMarket } from "../src/TickerlessMarket.sol";

interface VmMigration {
    function startBroadcast() external;
    function stopBroadcast() external;
}

/// @notice Moves the Base Sepolia demo-equity inventory onto Circle's official
/// testnet USDC and funds the device wallet used by the mobile demo.
contract MigrateOfficialUsdc {
    uint256 private constant BASE_SEPOLIA_CHAIN_ID = 84532;
    address private constant OFFICIAL_USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    address private constant OLD_MARKET = 0xe23B7a58BcF6B3E3F97E1120F2f473251596Bfb7;
    address private constant APP_WALLET = 0x10a26DC41Ba973ec1A9a37156fD67354992a6eE5;
    address private constant APPLE = 0xeCb227cCCCe78c2452188E656cDE26225fcbCD39;
    address private constant NVIDIA = 0xF1C8912F560B89779F00A59bcb5a43b5001f8FB2;
    address private constant META = 0x1a8BaBBE375b00D82281B4a5323B7587df0CEeE6;
    address private constant ALPHABET = 0xba66850b6bb6aD7460db33Ef057f0Ce6C022Df89;
    uint256 private constant APP_USDC = 15e6;
    uint256 private constant APP_GAS = 0.0003 ether;
    VmMigration private constant vm =
        VmMigration(address(uint160(uint256(keccak256("hevm cheat code")))));

    error FundingFailed();
    error UnsupportedChain(uint256 chainId);

    function run() external returns (TickerlessMarket market) {
        if (block.chainid != BASE_SEPOLIA_CHAIN_ID) revert UnsupportedChain(block.chainid);
        vm.startBroadcast();

        market = new TickerlessMarket(OFFICIAL_USDC);
        _moveAndList(market, APPLE, 200e6);
        _moveAndList(market, NVIDIA, 180e6);
        _moveAndList(market, META, 500e6);
        _moveAndList(market, ALPHABET, 150e6);

        if (!IERC20(OFFICIAL_USDC).transfer(APP_WALLET, APP_USDC)) revert FundingFailed();
        (bool funded,) = payable(APP_WALLET).call{ value: APP_GAS }("");
        if (!funded) revert FundingFailed();

        vm.stopBroadcast();
    }

    function _moveAndList(TickerlessMarket market, address asset, uint256 price) private {
        market.setAssetPrice(asset, price);
        uint256 inventory = DemoToken(asset).balanceOf(OLD_MARKET);
        TickerlessMarket(OLD_MARKET).withdrawAsset(asset, address(market), inventory);
    }
}
