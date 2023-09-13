// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ScaledNumber} from "../libraries/ScaledNumber.sol";

import {IDerivativesHandler} from "../interfaces/IDerivativesHandler.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";

contract BaseProtocol {
    using ScaledNumber for uint256;

    IAddressProvider internal immutable _addressProvider;

    uint256 internal _annualFeePercent;

    mapping(address => bool) public hasPosition;
    mapping(address => IDerivativesHandler.Position) public positions;
    mapping(address => uint256) public entryPrices;

    constructor(address addressProvider_, uint256 annualFeePercent_) {
        _addressProvider = IAddressProvider(addressProvider_);
        _annualFeePercent = annualFeePercent_;
    }

    function createPosition(
        address baseToken,
        address targetToken,
        uint256 baseAmount,
        uint256 leverage,
        bool isLong
    ) external {
        if (hasPosition[msg.sender])
            revert IDerivativesHandler.PositionAlreadyExists();

        IERC20(baseToken).transferFrom(msg.sender, address(this), baseAmount);
        hasPosition[msg.sender] = true;
        uint256 usdPrice_ = _usdPrice(targetToken);
        entryPrices[msg.sender] = usdPrice_;
        positions[msg.sender] = IDerivativesHandler.Position({
            createdAt: block.timestamp,
            baseToken: baseToken,
            targetToken: targetToken,
            baseAmount: baseAmount,
            leverage: leverage,
            isLong: isLong,
            hasProfit: false,
            delta: 0
        });
    }

    function closePosition() external returns (uint256) {
        if (!hasPosition[msg.sender])
            revert IDerivativesHandler.NoPositionExists();

        IDerivativesHandler.Position memory position_ = positions[msg.sender];
        (uint256 delta_, bool hasProfit_) = _profit(position_, msg.sender);
        uint256 owed_ = hasProfit_
            ? position_.baseAmount + delta_
            : position_.baseAmount - delta_;

        delete hasPosition[msg.sender];
        delete positions[msg.sender];
        delete entryPrices[msg.sender];
        IERC20(position_.baseToken).transfer(msg.sender, owed_);
        return owed_;
    }

    function updateFeePercent(uint256 annualFeePercent_) external {
        _annualFeePercent = annualFeePercent_;
    }

    function position(
        address user_
    ) external view returns (IDerivativesHandler.Position memory) {
        IDerivativesHandler.Position memory position_ = positions[user_];
        (position_.delta, position_.hasProfit) = _profit(position_, user_);
        return position_;
    }

    function _usdPrice(address token_) internal view returns (uint256) {
        return _addressProvider.oracle().getUsdPrice(token_);
    }

    function _profit(
        IDerivativesHandler.Position memory position_,
        address user_
    ) internal view returns (uint256 delta_, bool hasProfit_) {
        uint256 currentPrice_ = _usdPrice(position_.targetToken);
        uint256 entryPrice_ = entryPrices[user_];
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

    function _fee(
        IDerivativesHandler.Position memory position_
    ) internal view returns (uint256) {
        uint256 timePassed_ = block.timestamp - position_.createdAt;
        uint256 percentThroughYear_ = (timePassed_ * 1e18) / 365 days;
        uint256 loaned_ = position_.baseAmount.mul(position_.leverage);
        return loaned_.mul(_annualFeePercent).mul(percentThroughYear_);
    }

    function _absDiff(uint256 x_, uint256 y_) internal pure returns (uint256) {
        return x_ > y_ ? x_ - y_ : y_ - x_;
    }
}

contract MockDerivativesHandler is IDerivativesHandler {
    using ScaledNumber for uint256;

    BaseProtocol internal immutable _baseProtocol;

    constructor(address addressProvider_, uint256 annualFeePercent_) {
        _baseProtocol = new BaseProtocol(addressProvider_, annualFeePercent_);
    }

    function createPosition(
        address baseToken,
        address targetToken,
        uint256 baseAmount,
        uint256 leverage,
        bool isLong
    ) external override {
        _baseProtocol.createPosition(
            baseToken,
            targetToken,
            baseAmount,
            leverage,
            isLong
        );
    }

    function closePosition() external override returns (uint256) {
        return _baseProtocol.closePosition();
    }

    function updateFeePercent(uint256 annualFeePercent_) external {
        _baseProtocol.updateFeePercent(annualFeePercent_);
    }

    function position() external view override returns (Position memory) {
        return _baseProtocol.position(msg.sender);
    }

    function hasPosition() external view override returns (bool) {
        return _baseProtocol.hasPosition(msg.sender);
    }

    function approveAddress() external view override returns (address) {
        return address(_baseProtocol);
    }
}
