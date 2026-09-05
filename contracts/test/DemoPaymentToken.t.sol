// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { DemoPaymentToken } from "../src/DemoPaymentToken.sol";

interface VmPayment {
    function expectRevert(bytes4 selector) external;
    function prank(address sender) external;
}

contract DemoPaymentTokenTest {
    VmPayment private constant vm =
        VmPayment(address(uint160(uint256(keccak256("hevm cheat code")))));
    address private constant EXPLORER = address(0xA11CE);

    function testWalletCanClaimOnce() public {
        DemoPaymentToken token = new DemoPaymentToken();

        vm.prank(EXPLORER);
        token.claim();
        require(token.balanceOf(EXPLORER) == 1_000e6, "incorrect faucet amount");

        vm.expectRevert(DemoPaymentToken.AlreadyClaimed.selector);
        vm.prank(EXPLORER);
        token.claim();
    }
}
