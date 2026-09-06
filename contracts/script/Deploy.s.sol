// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { DemoToken } from "../src/DemoToken.sol";
import { DemoPaymentToken } from "../src/DemoPaymentToken.sol";
import { TickerlessMarket } from "../src/TickerlessMarket.sol";

interface VmScript {
    function startBroadcast() external;
    function stopBroadcast() external;
}

contract DeployTickerless {
    uint256 private constant BASE_SEPOLIA_CHAIN_ID = 84532;
    VmScript private constant vm =
        VmScript(address(uint160(uint256(keccak256("hevm cheat code")))));

    struct Deployment {
        DemoPaymentToken usdc;
        DemoToken apple;
        DemoToken nvidia;
        DemoToken meta;
        DemoToken alphabet;
        TickerlessMarket market;
    }

    error UnsupportedChain(uint256 chainId);

    function run() external returns (Deployment memory deployment) {
        if (block.chainid != BASE_SEPOLIA_CHAIN_ID) revert UnsupportedChain(block.chainid);
        vm.startBroadcast();

        deployment.usdc = new DemoPaymentToken();
        deployment.apple = new DemoToken("Demo Apple", "tAAPLc", 18);
        deployment.nvidia = new DemoToken("Demo NVIDIA", "tNVDAc", 18);
        deployment.meta = new DemoToken("Demo Meta", "tMETAc", 18);
        deployment.alphabet = new DemoToken("Demo Alphabet", "tGOOGLc", 18);
        deployment.market = new TickerlessMarket(address(deployment.usdc));

        _list(deployment.apple, deployment.market, 200e6);
        _list(deployment.nvidia, deployment.market, 180e6);
        _list(deployment.meta, deployment.market, 500e6);
        _list(deployment.alphabet, deployment.market, 150e6);

        vm.stopBroadcast();
    }

    function _list(DemoToken token, TickerlessMarket market, uint256 price) private {
        market.setAssetPrice(address(token), price);
        token.mint(address(market), 1_000e18);
    }
}
