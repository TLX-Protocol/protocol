// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {IPositionManager} from "./interfaces/IPositionManager.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";

contract PositionManager is IPositionManager {
    using ScaledNumber for uint256;

    IAddressProvider internal immutable _addressProvider;
    string public override targetAsset;
    IERC20Metadata internal immutable _baseAsset;
    uint8 internal immutable _baseDecimals;

    constructor(address addressProvider_, string memory targetAsset_) {
        _addressProvider = IAddressProvider(addressProvider_);
        targetAsset = targetAsset_;
        _baseAsset = _addressProvider.baseAsset();
        _baseDecimals = _baseAsset.decimals();
    }

    function mintAmountIn(
        address leveragedToken_,
        uint256 baseAmountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) external override returns (uint256) {
        if (!_isLeveragedToken(leveragedToken_)) revert NotLeveragedToken();
        if (!_isPositionManager(leveragedToken_)) revert NotPositionManager();

        if (baseAmountIn_ == 0) return 0;

        _baseAsset.transferFrom(msg.sender, address(this), baseAmountIn_);
        uint256 exchangeRate_ = exchangeRate(leveragedToken_);
        uint256 leveragedTokenAmount_ = baseAmountIn_
            .scaleFrom(_baseDecimals)
            .div(exchangeRate_);
        bool sufficient_ = leveragedTokenAmount_ >= minLeveragedTokenAmountOut_;
        if (!sufficient_) revert InsufficientAmount();
        ILeveragedToken(leveragedToken_).mint(
            msg.sender,
            leveragedTokenAmount_
        );
        emit Minted(
            leveragedToken_,
            msg.sender,
            baseAmountIn_,
            leveragedTokenAmount_
        );
        return leveragedTokenAmount_;
    }

    function mintAmountOut(
        address leveragedToken_,
        uint256 leveragedTokenAmountOut_,
        uint256 maxBaseAmountIn_
    ) external override returns (uint256) {
        if (!_isLeveragedToken(leveragedToken_)) revert NotLeveragedToken();
        if (!_isPositionManager(leveragedToken_)) revert NotPositionManager();

        if (leveragedTokenAmountOut_ == 0) return 0;

        uint256 exchangeRate_ = exchangeRate(leveragedToken_);
        uint256 baseAmountIn_ = leveragedTokenAmountOut_
            .mul(exchangeRate_)
            .scaleTo(_baseDecimals);
        bool sufficient_ = baseAmountIn_ <= maxBaseAmountIn_;
        if (!sufficient_) revert InsufficientAmount();
        _baseAsset.transferFrom(msg.sender, address(this), baseAmountIn_);
        ILeveragedToken(leveragedToken_).mint(
            msg.sender,
            leveragedTokenAmountOut_
        );
        emit Minted(
            leveragedToken_,
            msg.sender,
            baseAmountIn_,
            leveragedTokenAmountOut_
        );
        return baseAmountIn_;
    }

    function redeem(
        address leveragedToken_,
        uint256 leveragedTokenAmount_,
        uint256 minBaseAmountReceived_
    ) external override returns (uint256) {
        if (!_isLeveragedToken(leveragedToken_)) revert NotLeveragedToken();
        if (!_isPositionManager(leveragedToken_)) revert NotPositionManager();

        if (leveragedTokenAmount_ == 0) return 0;

        uint256 exchangeRate_ = exchangeRate(leveragedToken_);
        uint256 baseAmountReceived_ = leveragedTokenAmount_
            .mul(exchangeRate_)
            .scaleTo(_baseDecimals);
        bool sufficient_ = baseAmountReceived_ >= minBaseAmountReceived_;
        if (!sufficient_) revert InsufficientAmount();
        ILeveragedToken(leveragedToken_).burn(
            msg.sender,
            leveragedTokenAmount_
        );
        _baseAsset.transfer(msg.sender, baseAmountReceived_);

        emit Redeemed(
            leveragedToken_,
            msg.sender,
            baseAmountReceived_,
            leveragedTokenAmount_
        );
        return baseAmountReceived_;
    }

    function rebalance() external override returns (uint256) {
        // TODO implement
        return 0;
    }

    function exchangeRate(
        address /* leveragedToken_ */
    ) public view override returns (uint256) {
        // TODO implement
        return 2e18;
    }

    function _isLeveragedToken(address token_) internal view returns (bool) {
        return
            _addressProvider.leveragedTokenFactory().isLeveragedToken(token_);
    }

    function _isPositionManager(
        address leveragedToken_
    ) internal view returns (bool) {
        return
            _addressProvider.positionManagerFactory().positionManager(
                ILeveragedToken(leveragedToken_).targetAsset()
            ) == address(this);
    }
}
