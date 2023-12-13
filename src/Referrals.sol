// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {IReferrals} from "./interfaces/IReferrals.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";

contract Referrals is IReferrals, Ownable {
    using ScaledNumber for uint256;

    IAddressProvider internal immutable _addressProvider;

    mapping(address => bytes32) internal _codes;
    mapping(bytes32 => address) internal _referrers;
    mapping(address => bytes32) internal _referrals;
    // Earnings contains both referrer earnings and rebates
    mapping(address => uint256) internal _earnings;

    uint256 public override rebatePercent;
    uint256 public override earningsPercent;

    constructor(
        address addressProvider_,
        uint256 rebatePercent_,
        uint256 earningsPercent_
    ) {
        _addressProvider = IAddressProvider(addressProvider_);
        rebatePercent = rebatePercent_;
        earningsPercent = earningsPercent_;
    }

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

        uint256 earningsAmount_ = fees_.mul(earningsPercent);
        uint256 rebateAmount_ = fees_.mul(rebatePercent);
        if (earningsAmount_ == 0 && rebateAmount_ == 0) return 0;
        uint256 totalAmount_ = earningsAmount_ + rebateAmount_;
        _addressProvider.baseAsset().transferFrom(
            msg.sender,
            address(this),
            totalAmount_
        );
        _earnings[referrer_] += earningsAmount_;
        _earnings[user_] += rebateAmount_;
        return totalAmount_;
    }

    function claimEarnings() external override returns (uint256) {
        uint256 amount_ = _earnings[msg.sender];
        if (amount_ == 0) return 0;
        delete _earnings[msg.sender];
        _addressProvider.baseAsset().transfer(msg.sender, amount_);
        return amount_;
    }

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

    function updateReferral(bytes32 code_) external override {
        _updateCodeFor(code_, msg.sender);
    }

    function setRebatePercent(
        uint256 rebatePercent_
    ) external override onlyOwner {
        if (rebatePercent_ == rebatePercent) revert NotChanged();
        if (rebatePercent_ > 1e18) revert InvalidAmount();
        if (rebatePercent_ + earningsPercent > 1e18) revert InvalidAmount();
        rebatePercent = rebatePercent_;
        emit RebateSet(rebatePercent_);
    }

    function setEarningsPercent(
        uint256 earningsPercent_
    ) external override onlyOwner {
        if (earningsPercent_ == earningsPercent) revert NotChanged();
        if (earningsPercent_ + rebatePercent > 1e18) revert InvalidAmount();
        earningsPercent = earningsPercent_;
        emit EarningsSet(earningsPercent_);
    }

    function codeRebate(
        bytes32 code_
    ) external view override returns (uint256) {
        return _codeRebate(code_);
    }

    function userRebate(
        address user_
    ) external view override returns (uint256) {
        bytes32 code_ = _referrals[user_];
        if (code_ == bytes32(0)) return 0;
        return _codeRebate(code_);
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

    function earned(
        address referrer_
    ) external view override returns (uint256) {
        return _earnings[referrer_];
    }

    function _updateCodeFor(bytes32 code_, address user_) internal {
        if (_referrals[user_] == code_) revert SameCode();
        if (_referrers[code_] == address(0)) revert InvalidCode();
        _referrals[user_] = code_;
        emit UpdatedReferral(user_, code_);
    }

    function _codeRebate(bytes32 code_) internal view returns (uint256) {
        address referrer_ = _referrers[code_];
        if (referrer_ == address(0)) return 0;
        return rebatePercent;
    }
}
