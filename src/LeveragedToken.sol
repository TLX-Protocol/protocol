// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

import {TlxOwnable} from "./utils/TlxOwnable.sol";

import {Errors} from "./libraries/Errors.sol";
import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IStaker} from "./interfaces/IStaker.sol";
import {IReferrals} from "./interfaces/IReferrals.sol";
import {ISynthetixHandler} from "./interfaces/ISynthetixHandler.sol";

contract LeveragedToken is ILeveragedToken, ERC20, TlxOwnable {
    using ScaledNumber for uint256;
    using Address for address;

    IAddressProvider internal immutable _addressProvider;

    uint256 internal _lastStreamingFeeTimestamp;

    /// @inheritdoc ILeveragedToken
    string public override targetAsset;
    /// @inheritdoc ILeveragedToken
    uint256 public immutable override targetLeverage;
    /// @inheritdoc ILeveragedToken
    bool public immutable override isLong;
    /// @inheritdoc ILeveragedToken
    bool public override isPaused;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory targetAsset_,
        uint256 targetLeverage_,
        bool isLong_,
        address addressProvider_
    ) ERC20(name_, symbol_) TlxOwnable(addressProvider_) {
        targetAsset = targetAsset_;
        targetLeverage = targetLeverage_;
        isLong = isLong_;
        _addressProvider = IAddressProvider(addressProvider_);
    }

    /// @inheritdoc ILeveragedToken
    function mint(
        uint256 baseAmountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) public override returns (uint256) {
        if (baseAmountIn_ == 0) return 0;
        if (isPaused) revert Paused();
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

    /// @inheritdoc ILeveragedToken
    function redeem(
        uint256 leveragedTokenAmount_,
        uint256 minBaseAmountReceived_
    ) public override returns (uint256) {
        if (leveragedTokenAmount_ == 0) return 0;
        _ensureNoPendingLeverageUpdate();

        // Accounting
        uint256 exchangeRate_ = exchangeRate();
        uint256 baseWithdrawn_ = leveragedTokenAmount_.mul(exchangeRate_);
        IAddressProvider addressProvider_ = _addressProvider;
        uint256 feePercent_ = addressProvider_
            .parameterProvider()
            .redemptionFee();
        uint256 fee_ = baseWithdrawn_.mul(targetLeverage).mul(feePercent_);
        uint256 baseAmountReceived_ = baseWithdrawn_ - fee_;

        // Verifying sufficient amount
        bool sufficient_ = baseAmountReceived_ >= minBaseAmountReceived_;
        if (!sufficient_) revert InsufficientAmount();

        // Withdrawing margin
        _withdrawMargin(baseWithdrawn_);

        // Charging fees
        _chargeRedemptionFee(fee_);

        // Redeeming
        _burn(msg.sender, leveragedTokenAmount_);
        addressProvider_.baseAsset().transfer(msg.sender, baseAmountReceived_);
        emit Redeemed(msg.sender, baseAmountReceived_, leveragedTokenAmount_);

        // Rebalancing if necessary
        if (canRebalance()) _rebalance();

        return baseAmountReceived_;
    }

    /// @inheritdoc ILeveragedToken
    function rebalance() public override {
        bool canRebalance_ = _addressProvider.isRebalancer(msg.sender);
        if (!canRebalance_) revert Errors.NotAuthorized();
        if (!canRebalance()) revert CannotRebalance();
        _chargeRebalanceFee();
        _rebalance();
    }

    /// @inheritdoc ILeveragedToken
    function chargeStreamingFee() public {
        _chargeStreamingFee();
    }

    /// @inheritdoc ILeveragedToken
    function setIsPaused(bool isPaused_) public override onlyOwner {
        if (isPaused == isPaused_) revert Errors.SameAsCurrent();
        isPaused = isPaused_;
    }

    /// @inheritdoc ILeveragedToken
    function exchangeRate() public view override returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        uint256 totalValue_ = _addressProvider.synthetixHandler().totalValue(
            targetAsset,
            address(this)
        );
        if (totalSupply_ == 0) return 1e18;
        return totalValue_.div(totalSupply_);
    }

    /// @inheritdoc ILeveragedToken
    function isActive() public view override returns (bool) {
        return exchangeRate() > 0;
    }

    /// @inheritdoc ILeveragedToken
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

        // Can't rebalance if the leverageDeviationFactor is already within the threshold
        uint256 leverageDeviationFactor_ = _addressProvider
            .synthetixHandler()
            .leverageDeviationFactor(
                targetAsset,
                address(this),
                targetLeverage
            );
        return leverageDeviationFactor_ >= rebalanceThreshold();
    }

    /// @inheritdoc ILeveragedToken
    function rebalanceThreshold() public view override returns (uint256) {
        return
            _addressProvider.parameterProvider().rebalanceThreshold(
                address(this)
            );
    }

    function _rebalance() internal {
        // Charging streaming fee
        _chargeStreamingFee();

        // Rebalancing
        _submitLeverageUpdate();
        uint256 currentLeverage_ = _addressProvider.synthetixHandler().leverage(
            targetAsset,
            address(this)
        );
        emit Rebalanced(currentLeverage_);
    }

    function _chargeRedemptionFee(uint256 fee_) internal {
        // Paying referrals
        IAddressProvider addressProvider_ = _addressProvider;
        IReferrals referrals_ = addressProvider_.referrals();
        IERC20 baseAsset_ = addressProvider_.baseAsset();
        baseAsset_.approve(address(referrals_), fee_);
        uint256 referralAmount_ = referrals_.takeEarnings(fee_, msg.sender);

        // Sending fees to staker
        IStaker staker_ = addressProvider_.staker();
        uint256 amount_ = fee_ - referralAmount_;
        // TODO: Test
        if (amount_ != 0 && staker_.totalStaked() != 0) {
            baseAsset_.approve(address(staker_), amount_);
            staker_.donateRewards(amount_);
        }
    }

    function _chargeStreamingFee() internal {
        // First deposit, don't charge fee but start streaming
        if (_lastStreamingFeeTimestamp == 0) {
            _lastStreamingFeeTimestamp = block.timestamp;
            return;
        }

        // Accounting
        IAddressProvider addressProvider_ = _addressProvider;
        uint256 streamingFeePercent_ = addressProvider_
            .parameterProvider()
            .streamingFee();
        ISynthetixHandler synthetixHandler_ = addressProvider_
            .synthetixHandler();
        string memory targetAsset_ = targetAsset;
        uint256 notionalValue_ = synthetixHandler_.notionalValue(
            targetAsset_,
            address(this)
        );
        uint256 annualStreamingFee_ = notionalValue_.mul(streamingFeePercent_);
        uint256 pastTime_ = block.timestamp - _lastStreamingFeeTimestamp;
        uint256 fee_ = annualStreamingFee_.mul(pastTime_).div(365 days);
        if (fee_ == 0) return;

        // Sending fees to staker
        IStaker staker_ = _addressProvider.staker();
        if (staker_.totalStaked() == 0) return;
        _withdrawMargin(fee_);
        _addressProvider.baseAsset().approve(address(staker_), fee_);
        staker_.donateRewards(fee_);
        _lastStreamingFeeTimestamp = block.timestamp;
    }

    function _chargeRebalanceFee() internal {
        IAddressProvider addressProvider_ = _addressProvider;
        uint256 fee_ = addressProvider_.parameterProvider().rebalanceFee();
        uint256 remainingMargin_ = addressProvider_
            .synthetixHandler()
            .remainingMargin(targetAsset, address(this));
        if (fee_ >= remainingMargin_) return;
        _withdrawMargin(fee_);
        address receiver_ = addressProvider_.rebalanceFeeReceiver();
        addressProvider_.baseAsset().transfer(receiver_, fee_);
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
