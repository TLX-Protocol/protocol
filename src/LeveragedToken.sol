// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

import {Errors} from "./libraries/Errors.sol";
import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IStaker} from "./interfaces/IStaker.sol";
import {IReferrals} from "./interfaces/IReferrals.sol";

contract LeveragedToken is ILeveragedToken, ERC20 {
    using ScaledNumber for uint256;
    using Address for address;

    IAddressProvider internal immutable _addressProvider;

    uint256 internal _lastRebalanceTimestamp;

    string public override targetAsset;
    uint256 public immutable override targetLeverage;
    bool public immutable override isLong;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory targetAsset_,
        uint256 targetLeverage_,
        bool isLong_,
        address addressProvider_
    ) ERC20(name_, symbol_) {
        targetAsset = targetAsset_;
        targetLeverage = targetLeverage_;
        isLong = isLong_;
        _addressProvider = IAddressProvider(addressProvider_);
    }

    function mint(
        uint256 baseAmountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) public override returns (uint256) {
        if (baseAmountIn_ == 0) return 0;
        _ensureNoPendingLeverageUpdate();

        // Accounting
        uint256 exchangeRate_ = exchangeRate();
        uint256 leveragedTokenAmount_ = baseAmountIn_.div(exchangeRate_);

        // Verifying sufficient amount
        bool sufficient_ = leveragedTokenAmount_ >= minLeveragedTokenAmountOut_;
        if (!sufficient_) revert InsufficientAmount();

        // Minting
        _addressProvider.baseAsset().transferFrom(
            msg.sender,
            address(this),
            baseAmountIn_
        );
        _depositMargin(baseAmountIn_);
        _mint(msg.sender, leveragedTokenAmount_);
        emit Minted(msg.sender, baseAmountIn_, leveragedTokenAmount_);

        // Rebalancing if necessary
        if (canRebalance()) _rebalance();

        return leveragedTokenAmount_;
    }

    function redeem(
        uint256 leveragedTokenAmount_,
        uint256 minBaseAmountReceived_
    ) public override returns (uint256) {
        if (leveragedTokenAmount_ == 0) return 0;
        _ensureNoPendingLeverageUpdate();

        // Accounting
        uint256 exchangeRate_ = exchangeRate();
        uint256 baseWithdrawn_ = leveragedTokenAmount_.mul(exchangeRate_);
        uint256 feePercent_ = _addressProvider
            .parameterProvider()
            .redemptionFee();
        uint256 fee_ = baseWithdrawn_.mul(targetLeverage).mul(feePercent_);
        uint256 baseAmountReceived_ = baseWithdrawn_ - fee_;

        // Verifying sufficient amount
        bool sufficient_ = baseAmountReceived_ >= minBaseAmountReceived_;
        if (!sufficient_) revert InsufficientAmount();

        // Withdrawing margin
        _withdrawMargin(baseWithdrawn_);

        // Paying referrals
        IReferrals referrals_ = _addressProvider.referrals();
        _addressProvider.baseAsset().approve(address(referrals_), fee_);
        uint256 referralAmount_ = referrals_.takeEarnings(fee_, msg.sender);

        // Sending fees to staker
        IStaker staker_ = _addressProvider.staker();
        uint256 amount_ = fee_ - referralAmount_;
        if (amount_ != 0 && staker_.totalStaked() != 0) {
            _addressProvider.baseAsset().approve(address(staker_), amount_);
            staker_.donateRewards(amount_);
        }

        // Redeeming
        _burn(msg.sender, leveragedTokenAmount_);
        _addressProvider.baseAsset().transfer(msg.sender, baseAmountReceived_);
        emit Redeemed(msg.sender, baseAmountReceived_, leveragedTokenAmount_);

        // Rebalancing if necessary
        if (canRebalance()) _rebalance();

        return baseAmountReceived_;
    }

    function rebalance() public override {
        bool canRebalance_ = _addressProvider.isRebalancer(msg.sender);
        if (!canRebalance_) revert Errors.NotAuthorized();
        if (!canRebalance()) revert CannotRebalance();
        _chargeRebalanceFee();
        _rebalance();
    }

    function exchangeRate() public view override returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        uint256 totalValue = _addressProvider.synthetixHandler().totalValue(
            targetAsset,
            address(this)
        );
        if (totalSupply_ == 0) return 1e18;
        return totalValue.div(totalSupply_);
    }

    function isActive() public view override returns (bool) {
        return exchangeRate() > 0;
    }

    function canRebalance() public view override returns (bool) {
        // Can't rebalance if there is no margin
        if (
            _addressProvider.synthetixHandler().remainingMargin(
                targetAsset,
                address(this)
            ) == 0
        ) return false;

        // Can't rebalance if there is a pending leverage update
        if (
            _addressProvider.synthetixHandler().hasPendingLeverageUpdate(
                targetAsset,
                address(this)
            )
        ) return false;

        // Can't rebalance if the leverage is already within the threshold
        uint256 current_ = _addressProvider.synthetixHandler().leverage(
            targetAsset,
            address(this)
        );
        uint256 target_ = targetLeverage;
        uint256 diff_ = current_ > target_
            ? current_ - target_
            : target_ - current_;
        uint256 percentDiff_ = diff_.div(target_);
        return percentDiff_ >= rebalanceThreshold();
    }

    function rebalanceThreshold() public view override returns (uint256) {
        return
            _addressProvider.parameterProvider().rebalanceThreshold(
                address(this)
            );
    }

    function _rebalance() internal {
        // Accounting
        uint256 streamingFeePercent_ = _addressProvider
            .parameterProvider()
            .streamingFee();
        uint256 notionalValue_ = _addressProvider
            .synthetixHandler()
            .notionalValue(targetAsset, address(this));
        uint256 annualStreamingFee_ = notionalValue_.mul(streamingFeePercent_);
        uint256 pastTime_ = block.timestamp - _lastRebalanceTimestamp;
        uint256 fee_ = annualStreamingFee_.mul(pastTime_).div(365 days);

        // Sending fees to staker
        IStaker staker_ = _addressProvider.staker();
        if (fee_ != 0 && staker_.totalStaked() != 0) {
            _addressProvider.baseAsset().approve(address(staker_), fee_);
            staker_.donateRewards(fee_);
        }

        // Rebalancing
        _submitLeverageUpdate();
        _lastRebalanceTimestamp = block.timestamp;
        uint256 currentLeverage_ = _addressProvider.synthetixHandler().leverage(
            targetAsset,
            address(this)
        );
        emit Rebalanced(currentLeverage_);
    }

    function _chargeRebalanceFee() internal {
        uint256 fee_ = _addressProvider.parameterProvider().rebalanceFee();
        uint256 remainingMargin_ = _addressProvider
            .synthetixHandler()
            .remainingMargin(targetAsset, address(this));
        if (fee_ >= remainingMargin_) return;
        _withdrawMargin(fee_);
        address receiver_ = _addressProvider.rebalanceFeeReceiver();
        _addressProvider.baseAsset().transfer(receiver_, fee_);
    }

    function _depositMargin(uint256 amount_) internal {
        address(_addressProvider.synthetixHandler()).functionDelegateCall(
            abi.encodeWithSignature(
                "depositMargin(string,uint256)",
                targetAsset,
                amount_
            )
        );
    }

    function _withdrawMargin(uint256 amount_) internal {
        address(_addressProvider.synthetixHandler()).functionDelegateCall(
            abi.encodeWithSignature(
                "withdrawMargin(string,uint256)",
                targetAsset,
                amount_
            )
        );
    }

    function _submitLeverageUpdate() internal {
        address(_addressProvider.synthetixHandler()).functionDelegateCall(
            abi.encodeWithSignature(
                "submitLeverageUpdate(string,uint256,bool)",
                targetAsset,
                targetLeverage,
                isLong
            )
        );
    }

    function _ensureNoPendingLeverageUpdate() internal view {
        if (
            _addressProvider.synthetixHandler().hasPendingLeverageUpdate(
                targetAsset,
                address(this)
            )
        ) revert LeverageUpdatePending();
    }
}
