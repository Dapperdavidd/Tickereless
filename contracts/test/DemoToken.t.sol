// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { DemoToken } from "../src/DemoToken.sol";

interface VmToken {
    function expectRevert(bytes4 selector) external;
    function prank(address sender) external;
}

contract DemoTokenTest {
    VmToken private constant vm = VmToken(address(uint160(uint256(keccak256("hevm cheat code")))));
    address private constant HOLDER = address(0xA11CE);
    address private constant SPENDER = address(0xB0B);

    function testOwnerCanMintAndHolderCanTransfer() public {
        DemoToken token = new DemoToken("Demo NVIDIA", "tNVDAc", 18);
        token.mint(HOLDER, 10e18);
        vm.prank(HOLDER);
        require(token.transfer(SPENDER, 3e18), "transfer failed");
        require(token.balanceOf(HOLDER) == 7e18, "holder balance incorrect");
        require(token.balanceOf(SPENDER) == 3e18, "recipient balance incorrect");
    }

    function testNonOwnerCannotMint() public {
        DemoToken token = new DemoToken("Demo NVIDIA", "tNVDAc", 18);
        vm.expectRevert(DemoToken.Unauthorized.selector);
        vm.prank(HOLDER);
        token.mint(HOLDER, 1e18);
    }
}
