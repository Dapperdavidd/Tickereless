// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IERC20 } from "./IERC20.sol";

contract TickerlessMarket {
    uint256 private constant ASSET_UNIT = 1e18;

    IERC20 public immutable paymentToken;
    address public owner;
    bool private entered;

    mapping(address => uint256) public priceUsdc;

    error InsufficientOutput();
    error InvalidAmount();
    error InvalidPrice();
    error ReentrantCall();
    error TokenTransferFailed();
    error Unauthorized();
    error UnsupportedAsset();
    error ZeroAddress();

    event AssetPriceUpdated(address indexed asset, uint256 priceUsdc);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Purchased(
        address indexed buyer, address indexed asset, uint256 amountUsdc, uint256 tokenAmount
    );

    constructor(address paymentToken_) {
        if (paymentToken_ == address(0)) revert ZeroAddress();
        paymentToken = IERC20(paymentToken_);
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier nonReentrant() {
        if (entered) revert ReentrantCall();
        entered = true;
        _;
        entered = false;
    }

    function setAssetPrice(address asset, uint256 price) external onlyOwner {
        if (asset == address(0)) revert ZeroAddress();
        if (price == 0) revert InvalidPrice();
        priceUsdc[asset] = price;
        emit AssetPriceUpdated(asset, price);
    }

    function quote(address asset, uint256 amountUsdc) public view returns (uint256 tokenAmount) {
        uint256 price = priceUsdc[asset];
        if (price == 0) revert UnsupportedAsset();
        if (amountUsdc == 0) revert InvalidAmount();
        tokenAmount = (amountUsdc * ASSET_UNIT) / price;
        if (tokenAmount == 0) revert InvalidAmount();
    }

    function buy(address asset, uint256 amountUsdc, uint256 minimumTokenAmount)
        external
        nonReentrant
        returns (uint256 tokenAmount)
    {
        tokenAmount = quote(asset, amountUsdc);
        if (tokenAmount < minimumTokenAmount) revert InsufficientOutput();
        if (!paymentToken.transferFrom(msg.sender, owner, amountUsdc)) {
            revert TokenTransferFailed();
        }
        if (!IERC20(asset).transfer(msg.sender, tokenAmount)) revert TokenTransferFailed();
        emit Purchased(msg.sender, asset, amountUsdc, tokenAmount);
    }

    function withdrawAsset(address asset, address recipient, uint256 amount) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddress();
        if (!IERC20(asset).transfer(recipient, amount)) revert TokenTransferFailed();
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
