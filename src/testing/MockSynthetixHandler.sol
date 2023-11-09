// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ScaledNumber} from "../libraries/ScaledNumber.sol";

import {ISynthetixHandler} from "../interfaces/ISynthetixHandler.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";

contract BaseProtocol {
    using ScaledNumber for uint256;

    error NoPositionExists();
    error PositionAlreadyExists();

    struct Position {
        uint256 createdAt;
        string targetAsset;
        uint256 baseAmount;
        uint256 leverage;
        bool isLong;
        bool hasProfit;
        uint256 delta;
    }

    IAddressProvider internal immutable _addressProvider;

    uint256 internal _annualFeePercent;

    mapping(address => mapping(string => uint256)) public margin;
    mapping(address => mapping(string => bool)) public hasPosition;
    mapping(address => mapping(string => Position)) public positions;
    mapping(address => mapping(string => uint256)) public entryPrices;

    constructor(address addressProvider_, uint256 annualFeePercent_) {
        _addressProvider = IAddressProvider(addressProvider_);
        _annualFeePercent = annualFeePercent_;
    }

    function depositMargin(
        string calldata targetAsset_,
        uint256 amount_
    ) external {
        margin[msg.sender][targetAsset_] += amount_;
        _addressProvider.baseAsset().transferFrom(
            msg.sender,
            address(this),
            amount_
        );
    }

    function withdrawMargin(
        string calldata targetAsset_,
        uint256 amount_
    ) external {
        require(
            margin[msg.sender][targetAsset_] >= amount_,
            "Not enough margin"
        );
        margin[msg.sender][targetAsset_] -= amount_;
        _addressProvider.baseAsset().transfer(msg.sender, amount_);
    }

    // TODO Revise
    function createPosition(
        string calldata targetAsset,
        uint256 baseAmount,
        uint256 leverage,
        bool isLong
    ) external {
        if (hasPosition[msg.sender][targetAsset])
            revert PositionAlreadyExists();

        hasPosition[msg.sender][targetAsset] = true;
        uint256 usdPrice_ = _price(targetAsset);
        entryPrices[msg.sender][targetAsset] = usdPrice_;
        positions[msg.sender][targetAsset] = Position({
            createdAt: block.timestamp,
            targetAsset: targetAsset,
            baseAmount: baseAmount,
            leverage: leverage,
            isLong: isLong,
            hasProfit: false,
            delta: 0
        });
    }

    // TODO Revise
    function closePosition(
        string calldata targetAsset
    ) external returns (uint256) {
        if (!hasPosition[msg.sender][targetAsset]) revert NoPositionExists();

        Position memory position_ = positions[msg.sender][targetAsset];
        (uint256 delta_, bool hasProfit_) = _profit(position_, msg.sender);
        uint256 owed_ = hasProfit_
            ? position_.baseAmount + delta_
            : position_.baseAmount - delta_;

        delete hasPosition[msg.sender][targetAsset];
        delete positions[msg.sender][targetAsset];
        delete entryPrices[msg.sender][targetAsset];
        _addressProvider.baseAsset().transfer(msg.sender, owed_);
        return owed_;
    }

    function totalValue(
        address account,
        string calldata targetAsset
    ) external view returns (uint256) {
        if (!hasPosition[account][targetAsset]) return 0;

        Position memory position_ = positions[account][targetAsset];
        (uint256 delta_, bool hasProfit_) = _profit(position_, account);
        uint256 owed_ = hasProfit_
            ? position_.baseAmount + delta_
            : position_.baseAmount - delta_;

        return owed_;
    }

    // TODO Revise
    function updateFeePercent(uint256 annualFeePercent_) external {
        _annualFeePercent = annualFeePercent_;
    }

    // TODO Revise
    function position(
        address user_,
        string memory targetAsset
    ) external view returns (Position memory) {
        Position memory position_ = positions[user_][targetAsset];
        (position_.delta, position_.hasProfit) = _profit(position_, user_);
        return position_;
    }

    // TODO Revise
    function _price(string memory token_) internal view returns (uint256) {
        return _addressProvider.oracle().getPrice(token_);
    }

    // TODO Revise
    function _profit(
        Position memory position_,
        address user_
    ) internal view returns (uint256 delta_, bool hasProfit_) {
        uint256 currentPrice_ = _price(position_.targetAsset);
        uint256 entryPrice_ = entryPrices[user_][position_.targetAsset];
        uint256 priceDelta_ = _absDiff(currentPrice_, entryPrice_);
        uint256 percentDelta_ = priceDelta_.div(entryPrice_);
        uint256 scaledPercentDelta_ = percentDelta_.mul(position_.leverage);
        uint256 positionDelta_ = scaledPercentDelta_.mul(position_.baseAmount);
        bool isUp_ = currentPrice_ > entryPrice_;
        bool positionHasProfit_ = position_.isLong ? isUp_ : !isUp_;
        uint256 fee_ = _fee(position_);
        if (positionHasProfit_) {
            if (fee_ > positionDelta_) {
                return (fee_ - positionDelta_, false);
            }
            return (positionDelta_ - fee_, true);
        }
        return (positionDelta_ + fee_, false);
    }

    // TODO Revise
    function _fee(Position memory position_) internal view returns (uint256) {
        uint256 timePassed_ = block.timestamp - position_.createdAt;
        uint256 percentThroughYear_ = (timePassed_ * 1e18) / 365 days;
        uint256 loaned_ = position_.baseAmount.mul(position_.leverage);
        return loaned_.mul(_annualFeePercent).mul(percentThroughYear_);
    }

    function _absDiff(uint256 x_, uint256 y_) internal pure returns (uint256) {
        return x_ > y_ ? x_ - y_ : y_ - x_;
    }
}

contract MockSynthetixHandler is ISynthetixHandler {
    using ScaledNumber for uint256;

    BaseProtocol public immutable baseProtocol;
    IAddressProvider internal immutable _addressProvider;

    constructor(address addressProvider_, uint256 annualFeePercent_) {
        baseProtocol = new BaseProtocol(addressProvider_, annualFeePercent_);
        _addressProvider = IAddressProvider(addressProvider_);
    }

    function depositMargin(
        string calldata targetAsset_,
        uint256 amount_
    ) external {
        _addressProvider.baseAsset().approve(address(baseProtocol), amount_);
        baseProtocol.depositMargin(targetAsset_, amount_);
    }

    function withdrawMargin(
        string calldata targetAsset_,
        uint256 amount_
    ) external {
        baseProtocol.withdrawMargin(targetAsset_, amount_);
    }

    function submitLeverageUpdate(
        string calldata targetAsset_,
        uint256 leverage_,
        bool isLong_
    ) external {
        if (baseProtocol.hasPosition(address(this), targetAsset_)) {
            baseProtocol.closePosition(targetAsset_);
        }
        uint256 margin_ = baseProtocol.margin(address(this), targetAsset_);
        baseProtocol.createPosition(targetAsset_, margin_, leverage_, isLong_);
    }

    function hasOpenPosition(
        string calldata targetAsset_
    ) external view returns (bool) {
        return hasOpenPosition(targetAsset_, msg.sender);
    }

    function hasOpenPosition(
        string calldata targetAsset_,
        address account_
    ) public view returns (bool) {
        return baseProtocol.hasPosition(account_, targetAsset_);
    }

    function totalValue(
        string calldata targetAsset_
    ) external view returns (uint256) {
        return totalValue(targetAsset_, msg.sender);
    }

    function totalValue(
        string calldata targetAsset_,
        address account_
    ) public view returns (uint256) {
        return baseProtocol.totalValue(account_, targetAsset_);
    }

    function leverage(
        string calldata targetAsset_
    ) external view returns (uint256) {
        return baseProtocol.position(msg.sender, targetAsset_).leverage;
    }

    function leverage(
        string calldata targetAsset_,
        address account_
    ) public view returns (uint256) {
        return baseProtocol.position(account_, targetAsset_).leverage;
    }

    function notionalValue(
        string calldata targetAsset_
    ) external view returns (uint256) {
        return notionalValue(targetAsset_, msg.sender);
    }

    function notionalValue(
        string calldata targetAsset_,
        address account_
    ) public view returns (uint256) {
        if (!baseProtocol.hasPosition(account_, targetAsset_)) return 0;
        BaseProtocol.Position memory position = baseProtocol.position(
            account_,
            targetAsset_
        );
        return position.baseAmount.mul(position.leverage);
    }

    function isLong(string calldata targetAsset_) external view returns (bool) {
        return isLong(targetAsset_, msg.sender);
    }

    function isLong(
        string calldata targetAsset_,
        address account_
    ) public view returns (bool) {
        return baseProtocol.position(account_, targetAsset_).isLong;
    }

    function remainingMargin(
        string calldata targetAsset_
    ) external view returns (uint256) {
        return remainingMargin(targetAsset_, msg.sender);
    }

    function remainingMargin(
        string calldata targetAsset_,
        address account_
    ) public view returns (uint256) {
        return baseProtocol.margin(account_, targetAsset_);
    }

    function fillPrice(
        string calldata targetAsset_,
        int256
    ) external view returns (uint256) {
        return _addressProvider.oracle().getPrice(targetAsset_);
    }

    function assetPrice(
        string calldata targetAsset_
    ) external view returns (uint256) {
        return _addressProvider.oracle().getPrice(targetAsset_);
    }

    function isAssetSupported(
        string calldata targetAsset_
    ) external pure override returns (bool) {
        string[] memory supported_ = new string[](4);
        supported_[0] = "ETH";
        supported_[1] = "UNI";
        supported_[2] = "BTC";
        supported_[3] = "CRV";

        for (uint256 i; i < supported_.length; i++) {
            if (
                keccak256(abi.encodePacked(supported_[i])) ==
                keccak256(abi.encodePacked(targetAsset_))
            ) {
                return true;
            }
        }
        return false;
    }

    // Admin Functions

    function updateFeePercent(uint256 annualFeePercent_) external {
        baseProtocol.updateFeePercent(annualFeePercent_);
    }
}
