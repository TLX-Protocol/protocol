// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {IVesting} from "./interfaces/IVesting.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract Vesting is IVesting {
    using ScaledNumber for uint256;

    mapping(address => uint256) internal _amounts;
    IAddressProvider internal immutable _addressProvider;
    uint256 internal immutable _start;
    uint256 internal immutable _duration;

    mapping(address => uint256) public override claimed;
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

        for (uint256 i; i < amounts_.length; i++) {
            _amounts[amounts_[i].account] = amounts_[i].amount;
        }
    }

    function claim() public override {
        claim(msg.sender, msg.sender);
    }

    function claim(address account_, address to_) public override {
        bool isDelegate_ = isDelegate[account_][msg.sender];
        if (account_ != msg.sender && !isDelegate_) revert NotAuthorized();

        uint256 claimable_ = claimable(account_);
        if (claimable_ == 0) revert NothingToClaim();
        claimed[account_] += claimable_;
        _addressProvider.tlx().transfer(to_, claimable_);
        emit Claimed(account_, to_, claimable_);
    }

    function addDelegate(address delegate_) public override {
        isDelegate[msg.sender][delegate_] = true;
    }

    function removeDelegate(address delegate_) public override {
        isDelegate[msg.sender][delegate_] = false;
    }

    function allocated(
        address account_
    ) public view override returns (uint256) {
        return _amounts[account_];
    }

    function claimable(
        address account_
    ) public view override returns (uint256) {
        return vested(account_) - claimed[account_];
    }

    function vesting(address account_) public view override returns (uint256) {
        return _amounts[account_] - vested(account_);
    }

    function vested(address account_) public view override returns (uint256) {
        uint256 percent_ = (block.timestamp - _start).div(_duration);
        if (percent_ > 1e18) percent_ = 1e18;
        return _amounts[account_].mul(percent_);
    }
}
