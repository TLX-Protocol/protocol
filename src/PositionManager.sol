// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";
import {Errors} from "./libraries/Errors.sol";

import {IPositionManager} from "./interfaces/IPositionManager.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";

// TODO Rebalance during mint??
// TODO What if we need to rebalance to withdraw??
// TODO What if it is cancelled??
// TODO Rebalance during mint and redeems
// TODO Don't allow mint or redeems if there is a pending leverage update

contract PositionManager is IPositionManager {
    using ScaledNumber for uint256;
    using Address for address;

    IAddressProvider internal immutable _addressProvider;
    IERC20Metadata internal immutable _baseAsset;
    uint8 internal immutable _baseDecimals;
    uint256 internal immutable rebalanceThreshold;

    ILeveragedToken public override leveragedToken;

    constructor(address addressProvider_, uint256 rebalanceThreshold_) {
        _addressProvider = IAddressProvider(addressProvider_);
        _baseAsset = _addressProvider.baseAsset();
        _baseDecimals = _baseAsset.decimals();
        rebalanceThreshold = rebalanceThreshold_;
    }

    function mint(
        uint256 baseAmountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) external override returns (uint256) {
        if (baseAmountIn_ == 0) return 0;

        uint256 exchangeRate_ = exchangeRate();
        _baseAsset.transferFrom(msg.sender, address(this), baseAmountIn_);
        uint256 leveragedTokenAmount_ = baseAmountIn_
            .scaleFrom(_baseDecimals)
            .div(exchangeRate_);
        bool sufficient_ = leveragedTokenAmount_ >= minLeveragedTokenAmountOut_;
        if (!sufficient_) revert InsufficientAmount();
        _depositMargin(baseAmountIn_);
        leveragedToken.mint(msg.sender, leveragedTokenAmount_);
        emit Minted(msg.sender, baseAmountIn_, leveragedTokenAmount_);
        return leveragedTokenAmount_;
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
        _withdrawMargin(baseAmountReceived_);
        _baseAsset.transfer(msg.sender, baseAmountReceived_);

        emit Redeemed(msg.sender, baseAmountReceived_, leveragedTokenAmount_);
        return baseAmountReceived_;
    }

    function rebalance() external override {
        if (!canRebalance()) revert CannotRebalance();
        _submitLeverageUpdate(
            leveragedToken.targetLeverage(),
            leveragedToken.isLong()
        );
    }

    function setLeveragedToken(address leveragedToken_) external override {
        if (address(leveragedToken) != address(0)) {
            revert Errors.AlreadyExists();
        }
        leveragedToken = ILeveragedToken(leveragedToken_);
    }

    function exchangeRate() public view override returns (uint256) {
        uint256 totalSupply_ = leveragedToken.totalSupply();
        uint256 totalValue = _addressProvider.synthetixHandler().totalValue(
            leveragedToken.targetAsset()
        );
        if (totalSupply_ == 0) return 1e18;
        return totalValue.div(totalSupply_);
    }

    function canRebalance() public view override returns (bool) {
        // Can't rebalance if there is no margin
        if (
            _addressProvider.synthetixHandler().remainingMargin(
                leveragedToken.targetAsset()
            ) == 0
        ) return false;

        // Can't rebalance if there is a pending leverage update
        if (
            _addressProvider.synthetixHandler().hasPendingLeverageUpdate(
                leveragedToken.targetAsset(),
                address(this)
            )
        ) return false;

        // Can't rebalance if the leverage is already within the threshold
        uint256 current_ = _addressProvider.synthetixHandler().leverage(
            leveragedToken.targetAsset()
        );
        uint256 target_ = leveragedToken.targetLeverage();
        uint256 diff_ = current_ > target_
            ? current_ - target_
            : target_ - current_;
        uint256 percentDiff_ = diff_.div(target_);
        return percentDiff_ >= rebalanceThreshold;
    }

    function _depositMargin(uint256 amount_) internal {
        address(_addressProvider.synthetixHandler()).functionDelegateCall(
            abi.encodeWithSignature(
                "depositMargin(string,uint256)",
                leveragedToken.targetAsset(),
                amount_
            )
        );
    }

    function _withdrawMargin(uint256 amount_) internal {
        address(_addressProvider.synthetixHandler()).functionDelegateCall(
            abi.encodeWithSignature(
                "withdrawMargin(string,uint256)",
                leveragedToken.targetAsset(),
                amount_
            )
        );
    }

    function _submitLeverageUpdate(uint256 leverage_, bool isLong_) internal {
        address(_addressProvider.synthetixHandler()).functionDelegateCall(
            abi.encodeWithSignature(
                "submitLeverageUpdate(string,uint256,bool)",
                leveragedToken.targetAsset(),
                leverage_,
                isLong_
            )
        );
    }
}
