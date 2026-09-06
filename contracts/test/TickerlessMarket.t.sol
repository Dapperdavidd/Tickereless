// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { DemoToken } from "../src/DemoToken.sol";
import { TickerlessMarket } from "../src/TickerlessMarket.sol";

interface Vm {
    function expectRevert(bytes4 selector) external;
    function prank(address sender) external;
}

contract TickerlessMarketTest {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    address private constant BUYER = address(0xB0B);

    DemoToken private usdc;
    DemoToken private equity;
    TickerlessMarket private market;

    function setUp() public {
        usdc = new DemoToken("Test USDC", "tUSDC", 6);
        equity = new DemoToken("Demo Apple", "tAAPLc", 18);
        market = new TickerlessMarket(address(usdc));
        market.setAssetPrice(address(equity), 200e6);
        equity.mint(address(market), 1_000e18);
        usdc.mint(BUYER, 100e6);
    }

    function testQuoteUsesSixDecimalUsdcAndEighteenDecimalEquity() public view {
        require(market.quote(address(equity), 5e6) == 0.025e18, "incorrect quote");
    }

    function testBuyExchangesPaymentForFractionalEquity() public {
        vm.prank(BUYER);
        usdc.approve(address(market), 5e6);
        vm.prank(BUYER);
        uint256 received = market.buy(address(equity), 5e6, 0.025e18);

        require(received == 0.025e18, "incorrect output");
        require(equity.balanceOf(BUYER) == 0.025e18, "buyer did not receive equity");
        require(usdc.balanceOf(address(this)) == 5e6, "owner did not receive payment");
    }

    function testBuyEnforcesMinimumOutput() public {
        vm.prank(BUYER);
        usdc.approve(address(market), 5e6);
        vm.expectRevert(TickerlessMarket.InsufficientOutput.selector);
        vm.prank(BUYER);
        market.buy(address(equity), 5e6, 0.026e18);
    }

    function testOnlyOwnerCanSetPrice() public {
        vm.expectRevert(TickerlessMarket.Unauthorized.selector);
        vm.prank(BUYER);
        market.setAssetPrice(address(equity), 100e6);
    }

    function testUnsupportedAssetCannotBeQuoted() public {
        DemoToken unsupported = new DemoToken("Unsupported", "NONE", 18);
        vm.expectRevert(TickerlessMarket.UnsupportedAsset.selector);
        market.quote(address(unsupported), 1e6);
    }

    function testZeroAmountCannotBeQuoted() public {
        vm.expectRevert(TickerlessMarket.InvalidAmount.selector);
        market.quote(address(equity), 0);
    }

    function testBuyerCannotSpendWithoutApproval() public {
        vm.expectRevert(DemoToken.InsufficientAllowance.selector);
        vm.prank(BUYER);
        market.buy(address(equity), 5e6, 0);
    }

    function testOwnerCanWithdrawInventory() public {
        market.withdrawAsset(address(equity), BUYER, 2e18);
        require(equity.balanceOf(BUYER) == 2e18, "inventory was not withdrawn");
    }

    function testNonOwnerCannotWithdrawInventory() public {
        vm.expectRevert(TickerlessMarket.Unauthorized.selector);
        vm.prank(BUYER);
        market.withdrawAsset(address(equity), BUYER, 2e18);
    }

    function testOwnershipTransferMovesAdministration() public {
        market.transferOwnership(BUYER);
        vm.expectRevert(TickerlessMarket.Unauthorized.selector);
        market.setAssetPrice(address(equity), 100e6);

        vm.prank(BUYER);
        market.setAssetPrice(address(equity), 100e6);
        require(market.priceUsdc(address(equity)) == 100e6, "new owner cannot administer");
    }
}
