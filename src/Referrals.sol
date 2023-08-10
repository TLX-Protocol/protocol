// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {IReferrals} from "./interfaces/IReferrals.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IPositionManagerFactory} from "./interfaces/IPositionManagerFactory.sol";

// TODO Add ability to earn rewards and claim them
// TODO Add comments to inteface
contract Referrals is IReferrals, Ownable {
    address internal immutable _addressProvider;

    mapping(address => bytes32) internal _codes;
    mapping(bytes32 => address) internal _referrers;
    mapping(address => bytes32) internal _referrals;
    mapping(address => bool) internal _partners;

    uint256 public override referralDiscount;
    uint256 public override referralEarnings;
    uint256 public override partnerDiscount;
    uint256 public override partnerEarnings;

    modifier onlyPositionManager() {
        address positionManagerFactory_ = IAddressProvider(_addressProvider)
            .positionManagerFactory();
        bool isPositionManager_ = IPositionManagerFactory(
            positionManagerFactory_
        ).isPositionManager(msg.sender);

        if (!isPositionManager_) revert NotPositionManager();
        _;
    }

    constructor(
        address addressProvider_,
        uint256 referralDiscount_,
        uint256 referralEarnings_,
        uint256 partnerDiscount_,
        uint256 partnerEarnings_
    ) {
        _addressProvider = addressProvider_;
        referralDiscount = referralDiscount_;
        referralEarnings = referralEarnings_;
        partnerDiscount = partnerDiscount_;
        partnerEarnings = partnerEarnings_;
    }

    function register(bytes32 code_) external override {
        if (_referrers[code_] != address(0)) revert CodeTaken();
        if (_codes[msg.sender] != bytes32(0)) revert AlreadyRegistered();
        if (code_ == bytes32(0)) revert InvalidCode();
        _codes[msg.sender] = code_;
        _referrers[code_] = msg.sender;
        emit Registered(msg.sender, code_);
    }

    function updateReferral(bytes32 code_) external override {
        _updateCodeFor(code_, msg.sender);
    }

    function updateReferralFor(
        address user_,
        bytes32 code_
    ) external override onlyPositionManager {
        _updateCodeFor(code_, user_);
    }

    function setPartner(
        address referrer_,
        bool isPartner_
    ) external override onlyOwner {
        if (_partners[referrer_] == isPartner_) revert NotChanged();
        _partners[referrer_] = isPartner_;
        emit PartnerSet(referrer_, isPartner_);
    }

    function setReferralDiscount(
        uint256 discount_
    ) external override onlyOwner {
        if (discount_ == referralDiscount) revert NotChanged();
        if (discount_ > 1e18) revert InvalidAmount();
        if (discount_ + referralEarnings > 1e18) revert InvalidAmount();
        referralDiscount = discount_;
        emit ReferralDiscountSet(discount_);
    }

    function setReferralEarnings(
        uint256 earnings_
    ) external override onlyOwner {
        if (earnings_ == referralEarnings) revert NotChanged();
        if (earnings_ > 1e18) revert InvalidAmount();
        if (earnings_ + referralDiscount > 1e18) revert InvalidAmount();
        referralEarnings = earnings_;
        emit ReferralEarningsSet(earnings_);
    }

    function setPartnerDiscount(uint256 discount_) external override onlyOwner {
        if (discount_ == partnerDiscount) revert NotChanged();
        if (discount_ > 1e18) revert InvalidAmount();
        if (discount_ + partnerEarnings > 1e18) revert InvalidAmount();
        partnerDiscount = discount_;
        emit PartnerDiscountSet(discount_);
    }

    function setPartnerEarnings(uint256 earnings_) external override onlyOwner {
        if (earnings_ == partnerEarnings) revert NotChanged();
        if (earnings_ > 1e18) revert InvalidAmount();
        if (earnings_ + partnerDiscount > 1e18) revert InvalidAmount();
        partnerEarnings = earnings_;
        emit PartnerEarningsSet(earnings_);
    }

    function discount(bytes32 code_) external view override returns (uint256) {
        return _codeDiscount(code_);
    }

    function discount(address user_) external view override returns (uint256) {
        bytes32 code_ = _referrals[user_];
        if (code_ == bytes32(0)) return 0;
        return _codeDiscount(code_);
    }

    function referrer(bytes32 code_) external view override returns (address) {
        return _referrers[code_];
    }

    function code(address referrer_) external view override returns (bytes32) {
        return _codes[referrer_];
    }

    function referral(address user_) external view override returns (bytes32) {
        return _referrals[user_];
    }

    function isPartner(
        address referrer_
    ) external view override returns (bool) {
        return _partners[referrer_];
    }

    function _updateCodeFor(bytes32 code_, address user_) internal {
        if (_referrals[user_] == code_) revert SameCode();
        if (_referrers[code_] == address(0)) revert InvalidCode();
        _referrals[user_] = code_;
        emit UpdatedReferral(user_, code_);
    }

    function _codeDiscount(bytes32 code_) internal view returns (uint256) {
        address referrer_ = _referrers[code_];
        if (referrer_ == address(0)) return 0;
        bool isPartner_ = _partners[referrer_];
        if (isPartner_) return partnerDiscount;
        return referralDiscount;
    }
}
