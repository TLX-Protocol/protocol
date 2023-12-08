// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";
import {Errors} from "./libraries/Errors.sol";

import {IPositionManager} from "./interfaces/IPositionManager.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";

contract PositionManager is IPositionManager {
    using ScaledNumber for uint256;

    IAddressProvider internal immutable _addressProvider;
    IERC20Metadata internal immutable _baseAsset;
    uint8 internal immutable _baseDecimals;

    ILeveragedToken public override leveragedToken;

    constructor(address addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
        _baseAsset = _addressProvider.baseAsset();
        _baseDecimals = _baseAsset.decimals();
    }

    function mintAmountIn(
        uint256 baseAmountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) external override returns (uint256) {
        if (baseAmountIn_ == 0) return 0;

        _baseAsset.transferFrom(msg.sender, address(this), baseAmountIn_);
        uint256 exchangeRate_ = exchangeRate();
        uint256 leveragedTokenAmount_ = baseAmountIn_
            .scaleFrom(_baseDecimals)
            .div(exchangeRate_);
        bool sufficient_ = leveragedTokenAmount_ >= minLeveragedTokenAmountOut_;
        if (!sufficient_) revert InsufficientAmount();
        leveragedToken.mint(msg.sender, leveragedTokenAmount_);
        emit Minted(msg.sender, baseAmountIn_, leveragedTokenAmount_);
        return leveragedTokenAmount_;
    }

    function mintAmountOut(
        uint256 leveragedTokenAmountOut_,
        uint256 maxBaseAmountIn_
    ) external override returns (uint256) {
        if (leveragedTokenAmountOut_ == 0) return 0;

        uint256 exchangeRate_ = exchangeRate();
        uint256 baseAmountIn_ = leveragedTokenAmountOut_
            .mul(exchangeRate_)
            .scaleTo(_baseDecimals);
        bool sufficient_ = baseAmountIn_ <= maxBaseAmountIn_;
        if (!sufficient_) revert InsufficientAmount();
        _baseAsset.transferFrom(msg.sender, address(this), baseAmountIn_);
        leveragedToken.mint(msg.sender, leveragedTokenAmountOut_);
        emit Minted(msg.sender, baseAmountIn_, leveragedTokenAmountOut_);
        return baseAmountIn_;
    }

    function redeem(
        uint256 leveragedTokenAmount_,
        uint256 minBaseAmountReceived_
    ) external override returns (uint256) {
        if (leveragedTokenAmount_ == 0) return 0;

        uint256 exchangeRate_ = exchangeRate();
        uint256 baseAmountReceived_ = leveragedTokenAmount_
            .mul(exchangeRate_)
            .scaleTo(_baseDecimals);
        bool sufficient_ = baseAmountReceived_ >= minBaseAmountReceived_;
        if (!sufficient_) revert InsufficientAmount();
        leveragedToken.burn(msg.sender, leveragedTokenAmount_);
        _baseAsset.transfer(msg.sender, baseAmountReceived_);

        emit Redeemed(msg.sender, baseAmountReceived_, leveragedTokenAmount_);
        return baseAmountReceived_;
    }

    function rebalance() external override returns (uint256) {
        // TODO implement
        return 0;
    }

    function setLeveragedToken(address leveragedToken_) external override {
        if (address(leveragedToken) != address(0)) {
            revert Errors.AlreadyExists();
        }
        leveragedToken = ILeveragedToken(leveragedToken_);
    }

    function exchangeRate() public view override returns (uint256) {
        // TODO implement
        return 2e18;
    }
}
