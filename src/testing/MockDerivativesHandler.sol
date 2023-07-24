// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ScaledNumber} from "../libraries/ScaledNumber.sol";

import {IDerivativesHandler} from "../interfaces/IDerivativesHandler.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IOracle} from "../interfaces/IOracle.sol";

contract MockDerivativesHandler is IDerivativesHandler {
    using ScaledNumber for uint256;

    uint256 internal immutable _fee; // TODO Add fee support

    bool internal _hasPosition;
    Position internal _position;
    uint256 internal _entryPrice;

    address internal _addressProvider;

    constructor(address addressProvider_, uint256 fee_) {
        _fee = fee_;
        _addressProvider = addressProvider_;
    }

    function createPosition(
        address baseToken,
        address targetToken,
        uint256 baseAmount,
        uint256 leverage,
        bool isLong
    ) external override {
        if (_hasPosition) revert PositionAlreadyExists();

        // TODO Change to delegate call
        IERC20(baseToken).transferFrom(msg.sender, address(this), baseAmount);
        _hasPosition = true;
        _entryPrice = _usdPrice(targetToken);
        _position = Position({
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

    function closePosition() external override returns (uint256) {
        if (!_hasPosition) revert NoPositionExists();

        (uint256 delta_, bool hasProfit_) = _profit(_position);
        Position memory position_ = _position;
        uint256 owed_ = hasProfit_
            ? position_.baseAmount + delta_
            : position_.baseAmount - delta_;

        delete _hasPosition;
        delete _position;
        delete _entryPrice;
        IERC20(position_.baseToken).transfer(msg.sender, owed_);
        return owed_;
    }

    function position() external view override returns (Position memory) {
        Position memory position_ = _position;
        (position_.delta, position_.hasProfit) = _profit(position_);
        return position_;
    }

    function hasPosition() external view override returns (bool) {
        return _hasPosition;
    }

    function _profit(
        Position memory position_
    ) internal view returns (uint256 delta_, bool hasProfit_) {
        uint256 currentPrice_ = _usdPrice(position_.targetToken);
        uint256 priceDelta_ = _absDiff(currentPrice_, _entryPrice);
        uint256 percentDelta_ = priceDelta_.div(_entryPrice);
        uint256 scaledPercentDelta_ = percentDelta_.mul(position_.leverage);
        delta_ = scaledPercentDelta_.mul(position_.baseAmount);
        bool isUp_ = currentPrice_ > _entryPrice;
        hasProfit_ = position_.isLong ? isUp_ : !isUp_;
    }

    function _usdPrice(address token_) internal view returns (uint256) {
        return
            IOracle(IAddressProvider(_addressProvider).oracle()).getUsdPrice(
                token_
            );
    }

    function _absDiff(uint256 x_, uint256 y_) internal pure returns (uint256) {
        return x_ > y_ ? x_ - y_ : y_ - x_;
    }
}
