// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {TlxOwnable} from "./utils/TlxOwnable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {IReferrals} from "./interfaces/IReferrals.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";

contract Referrals is IReferrals, TlxOwnable {
    using ScaledNumber for uint256;

    IAddressProvider internal immutable _addressProvider;

    mapping(address => bytes32) internal _codes;
    mapping(bytes32 => address) internal _referrers;
    mapping(address => bytes32) internal _referrals;
    // Earnings contains both referrer earnings and rebates
    mapping(address => uint256) internal _earnings;

    /// @inheritdoc IReferrals
    uint256 public override rebatePercent;
    /// @inheritdoc IReferrals
    uint256 public override referralPercent;

    constructor(
        address addressProvider_,
        uint256 rebatePercent_,
        uint256 referralPercent_
    ) TlxOwnable(addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
        rebatePercent = rebatePercent_;
        referralPercent = referralPercent_;
    }

    /// @inheritdoc IReferrals
    function takeEarnings(
        uint256 fees_,
        address user_
    ) external override returns (uint256) {
        if (fees_ == 0) return 0;
        if (user_ == address(0)) return 0;
        bytes32 code_ = _referrals[user_];
        if (code_ == bytes32(0)) return 0;
        address referrer_ = _referrers[code_];
        if (referrer_ == address(0)) return 0;

        uint256 referralAmount_ = fees_.mul(referralPercent);
        uint256 rebateAmount_ = fees_.mul(rebatePercent);
        if (referralAmount_ == 0 && rebateAmount_ == 0) return 0;
        uint256 totalAmount_ = referralAmount_ + rebateAmount_;
        _addressProvider.baseAsset().transferFrom(
            msg.sender,
            address(this),
            totalAmount_
        );
        _earnings[referrer_] += referralAmount_;
        _earnings[user_] += rebateAmount_;
        emit ReferralEarned(referrer_, referralAmount_);
        emit RebateEarned(user_, rebateAmount_);
        return totalAmount_;
    }

    /// @inheritdoc IReferrals
    function claimEarnings() external override returns (uint256) {
        uint256 amount_ = _earnings[msg.sender];
        if (amount_ == 0) return 0;
        delete _earnings[msg.sender];
        _addressProvider.baseAsset().transfer(msg.sender, amount_);
        emit EarningsClaimed(msg.sender, amount_);
        return amount_;
    }

    /// @inheritdoc IReferrals
    function register(
        address referrer_,
        bytes32 code_
    ) external override onlyOwner {
        if (_referrers[code_] != address(0)) revert CodeTaken();
        if (_codes[referrer_] != bytes32(0)) revert AlreadyRegistered();
        if (code_ == bytes32(0)) revert InvalidCode();
        _codes[referrer_] = code_;
        _referrers[code_] = referrer_;
        emit Registered(referrer_, code_);
    }

    /// @inheritdoc IReferrals
    function updateReferral(bytes32 code_) external override {
        if (_referrals[msg.sender] == code_) revert SameCode();
        if (_referrers[code_] == address(0)) revert InvalidCode();
        _referrals[msg.sender] = code_;
        emit UpdatedReferral(msg.sender, code_);
    }

    /// @inheritdoc IReferrals
    function setRebatePercent(
        uint256 rebatePercent_
    ) external override onlyOwner {
        if (rebatePercent_ == rebatePercent) revert NotChanged();
        if (rebatePercent_ > 1e18) revert InvalidAmount();
        if (rebatePercent_ + referralPercent > 1e18) revert InvalidAmount();
        rebatePercent = rebatePercent_;
        emit RebateSet(rebatePercent_);
    }

    /// @inheritdoc IReferrals
    function setReferralPercent(
        uint256 referralPercent_
    ) external override onlyOwner {
        if (referralPercent_ == referralPercent) revert NotChanged();
        if (referralPercent_ + rebatePercent > 1e18) revert InvalidAmount();
        referralPercent = referralPercent_;
        emit EarningsSet(referralPercent_);
    }

    /// @inheritdoc IReferrals
    function codeRebate(
        bytes32 code_
    ) external view override returns (uint256) {
        return _codeRebate(code_);
    }

    /// @inheritdoc IReferrals
    function userRebate(
        address user_
    ) external view override returns (uint256) {
        bytes32 code_ = _referrals[user_];
        if (code_ == bytes32(0)) return 0;
        return _codeRebate(code_);
    }

    /// @inheritdoc IReferrals
    function referrer(bytes32 code_) external view override returns (address) {
        return _referrers[code_];
    }

    /// @inheritdoc IReferrals
    function code(address referrer_) external view override returns (bytes32) {
        return _codes[referrer_];
    }

    /// @inheritdoc IReferrals
    function referral(address user_) external view override returns (bytes32) {
        return _referrals[user_];
    }

    /// @inheritdoc IReferrals
    function earned(
        address referrer_
    ) external view override returns (uint256) {
        return _earnings[referrer_];
    }

    function _codeRebate(bytes32 code_) internal view returns (uint256) {
        address referrer_ = _referrers[code_];
        if (referrer_ == address(0)) return 0;
        return rebatePercent;
    }
}
