// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";
import {Errors} from "./libraries/Errors.sol";

import {IPositionManager} from "./interfaces/IPositionManager.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";
import {IReferrals} from "./interfaces/IReferrals.sol";
import {ILocker} from "./interfaces/ILocker.sol";

contract PositionManager is IPositionManager, Ownable {
    using ScaledNumber for uint256;
    using Address for address;

    uint256 internal constant _MIN_REBALANCE_THRESHOLD = 0.01e18;
    uint256 internal constant _MAX_REBALANCE_THRESHOLD = 0.8e18;

    IAddressProvider internal immutable _addressProvider;
    IERC20Metadata internal immutable _baseAsset;

    uint256 internal _lastRebalanceTimestamp;

    ILeveragedToken public override leveragedToken;
    uint256 public override rebalanceThreshold;

    constructor(address addressProvider_, uint256 rebalanceThreshold_) {
        _addressProvider = IAddressProvider(addressProvider_);
        _baseAsset = _addressProvider.baseAsset();
        rebalanceThreshold = rebalanceThreshold_;
    }

    function mint(
        uint256 baseAmountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) external override returns (uint256) {
        if (baseAmountIn_ == 0) return 0;
        if (
            _addressProvider.synthetixHandler().hasPendingLeverageUpdate(
                leveragedToken.targetAsset(),
                address(this)
            )
        ) revert LeverageUpdatePending();

        // Accounting
        uint256 exchangeRate_ = exchangeRate();
        uint256 leveragedTokenAmount_ = baseAmountIn_.div(exchangeRate_);

        // Verifying sufficient amount
        bool sufficient_ = leveragedTokenAmount_ >= minLeveragedTokenAmountOut_;
        if (!sufficient_) revert InsufficientAmount();

        // Minting
        _baseAsset.transferFrom(msg.sender, address(this), baseAmountIn_);
        _depositMargin(baseAmountIn_);
        leveragedToken.mint(msg.sender, leveragedTokenAmount_);
        emit Minted(msg.sender, baseAmountIn_, leveragedTokenAmount_);

        // Rebalancing if necessary
        if (canRebalance()) rebalance();

        return leveragedTokenAmount_;
    }

    function redeem(
        uint256 leveragedTokenAmount_,
        uint256 minBaseAmountReceived_
    ) external override returns (uint256) {
        if (leveragedTokenAmount_ == 0) return 0;
        if (
            _addressProvider.synthetixHandler().hasPendingLeverageUpdate(
                leveragedToken.targetAsset(),
                address(this)
            )
        ) revert LeverageUpdatePending();

        // Accounting
        uint256 exchangeRate_ = exchangeRate();
        uint256 baseAmountReceived_ = leveragedTokenAmount_.mul(exchangeRate_);
        uint256 feePercent_ = _addressProvider
            .parameterProvider()
            .redemptionFee();
        uint256 fee_ = baseAmountReceived_
            .mul(leveragedToken.targetLeverage())
            .mul(feePercent_);
        baseAmountReceived_ = baseAmountReceived_ - fee_;

        // Verifying sufficient amount
        bool sufficient_ = baseAmountReceived_ >= minBaseAmountReceived_;
        if (!sufficient_) revert InsufficientAmount();

        // Paying referrals
        IReferrals referrals_ = _addressProvider.referrals();
        _addressProvider.baseAsset().approve(address(referrals_), fee_);
        uint256 referralAmount_ = referrals_.takeEarnings(fee_, msg.sender);

        // Sending fees to locker
        ILocker locker_ = _addressProvider.locker();
        uint256 amount_ = fee_ - referralAmount_;
        if (amount_ != 0 && locker_.totalLocked() != 0) {
            _addressProvider.baseAsset().approve(address(locker_), amount_);
            locker_.donateRewards(amount_);
        }

        // Redeeming
        leveragedToken.burn(msg.sender, leveragedTokenAmount_);
        _withdrawMargin(baseAmountReceived_);
        _baseAsset.transfer(msg.sender, baseAmountReceived_);
        emit Redeemed(msg.sender, baseAmountReceived_, leveragedTokenAmount_);

        // Rebalancing if necessary
        if (canRebalance()) rebalance();

        return baseAmountReceived_;
    }

    function rebalance() public override {
        if (!canRebalance()) revert CannotRebalance();

        // Accounting
        uint256 streamingFeePercent_ = _addressProvider
            .parameterProvider()
            .streamingFee();
        uint256 notionalValue_ = _addressProvider
            .synthetixHandler()
            .notionalValue(leveragedToken.targetAsset(), address(this));
        uint256 annualStreamingFee_ = notionalValue_.mul(streamingFeePercent_);
        uint256 pastTime_ = block.timestamp - _lastRebalanceTimestamp;
        uint256 fee_ = annualStreamingFee_.mul(pastTime_).div(365 days);

        // Sending fees to locker
        ILocker locker_ = _addressProvider.locker();
        if (fee_ != 0 && locker_.totalLocked() != 0) {
            _addressProvider.baseAsset().approve(address(locker_), fee_);
            locker_.donateRewards(fee_);
        }

        // Rebalancing
        _submitLeverageUpdate();
        _lastRebalanceTimestamp = block.timestamp;
    }

    function setLeveragedToken(address leveragedToken_) public override {
        if (address(leveragedToken) != address(0)) {
            revert Errors.AlreadyExists();
        }
        leveragedToken = ILeveragedToken(leveragedToken_);
    }

    function setRebalanceThreshold(
        uint256 rebalanceThreshold_
    ) public override onlyOwner {
        if (rebalanceThreshold_ < _MIN_REBALANCE_THRESHOLD) {
            revert InvalidRebalanceThreshold();
        }
        if (rebalanceThreshold_ > _MAX_REBALANCE_THRESHOLD) {
            revert InvalidRebalanceThreshold();
        }
        if (rebalanceThreshold_ == rebalanceThreshold) {
            revert InvalidRebalanceThreshold();
        }
        rebalanceThreshold = rebalanceThreshold_;
    }

    function exchangeRate() public view override returns (uint256) {
        uint256 totalSupply_ = leveragedToken.totalSupply();
        uint256 totalValue = _addressProvider.synthetixHandler().totalValue(
            leveragedToken.targetAsset(),
            address(this)
        );
        if (totalSupply_ == 0) return 1e18;
        return totalValue.div(totalSupply_);
    }

    function canRebalance() public view override returns (bool) {
        // Can't rebalance if there is no margin
        if (
            _addressProvider.synthetixHandler().remainingMargin(
                leveragedToken.targetAsset(),
                address(this)
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
            leveragedToken.targetAsset(),
            address(this)
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

    function _submitLeverageUpdate() internal {
        address(_addressProvider.synthetixHandler()).functionDelegateCall(
            abi.encodeWithSignature(
                "submitLeverageUpdate(string,uint256,bool)",
                leveragedToken.targetAsset(),
                leveragedToken.targetLeverage(),
                leveragedToken.isLong()
            )
        );
    }
}
