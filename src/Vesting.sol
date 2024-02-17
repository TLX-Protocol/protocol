// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {Errors} from "./libraries/Errors.sol";

import {IVesting} from "./interfaces/IVesting.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract Vesting is IVesting {
    using ScaledNumber for uint256;

    mapping(address => uint256) internal _amounts;
    IAddressProvider internal immutable _addressProvider;
    uint256 internal immutable _start;
    uint256 internal immutable _duration;

    /// @inheritdoc IVesting
    mapping(address => uint256) public override claimed;
    /// @inheritdoc IVesting
    mapping(address => mapping(address => bool)) public override isDelegate;

    constructor(
        address addressProvider_,
        uint256 duration_,
        VestingAmount[] memory amounts_
    ) {
        if (duration_ == 0) revert InvalidDuration();

        _addressProvider = IAddressProvider(addressProvider_);
        _start = block.timestamp;
        _duration = duration_;

        for (uint256 i_; i_ < amounts_.length; i_++) {
            _amounts[amounts_[i_].account] = amounts_[i_].amount;
        }
    }

    /// @inheritdoc IVesting
    function claim() public override {
        claim(msg.sender, msg.sender);
    }

    /// @inheritdoc IVesting
    function claim(address account_, address to_) public override {
        bool isDelegate_ = isDelegate[account_][msg.sender];
        if (account_ != msg.sender && !isDelegate_) revert NotAuthorized();

        uint256 claimable_ = claimable(account_);
        if (claimable_ == 0) revert NothingToClaim();
        claimed[account_] += claimable_;
        _addressProvider.tlx().transfer(to_, claimable_);
        emit Claimed(account_, to_, claimable_);
    }

    /// @inheritdoc IVesting
    function addDelegate(address delegate_) public override {
        if (delegate_ == address(0)) revert Errors.ZeroAddress();
        if (isDelegate[msg.sender][delegate_]) revert Errors.AlreadyExists();
        isDelegate[msg.sender][delegate_] = true;
        emit DelegateAdded(msg.sender, delegate_);
    }

    /// @inheritdoc IVesting
    function removeDelegate(address delegate_) public override {
        if (delegate_ == address(0)) revert Errors.ZeroAddress();
        if (!isDelegate[msg.sender][delegate_]) revert Errors.DoesNotExist();
        delete isDelegate[msg.sender][delegate_];
        emit DelegateRemoved(msg.sender, delegate_);
    }

    /// @inheritdoc IVesting
    function allocated(
        address account_
    ) public view override returns (uint256) {
        return _amounts[account_];
    }

    /// @inheritdoc IVesting
    function claimable(
        address account_
    ) public view override returns (uint256) {
        return vested(account_) - claimed[account_];
    }

    /// @inheritdoc IVesting
    function vesting(address account_) public view override returns (uint256) {
        return _amounts[account_] - vested(account_);
    }

    /// @inheritdoc IVesting
    function vested(address account_) public view override returns (uint256) {
        uint256 percent_ = (block.timestamp - _start).div(_duration);
        if (percent_ > 1e18) percent_ = 1e18;
        return _amounts[account_].mul(percent_);
    }
}
