// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {IVesting} from "./interfaces/IVesting.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ITlxToken} from "./interfaces/ITlxToken.sol";

contract Vesting is IVesting {
    using ScaledNumber for uint256;

    mapping(address => uint256) internal _amounts;
    mapping(address => uint256) internal _claimed;

    address internal immutable _addressProvider;
    uint256 internal immutable _start;
    uint256 internal immutable _duration;

    constructor(
        address addressProvider_,
        uint256 duration_,
        VestingAmount[] memory amounts_
    ) {
        if (duration_ == 0) revert InvalidDuration();

        _addressProvider = addressProvider_;
        _start = block.timestamp;
        _duration = duration_;

        for (uint256 i; i < amounts_.length; i++) {
            _amounts[amounts_[i].account] = amounts_[i].amount;
        }
    }

    function claim() external override {
        uint256 claimable_ = claimable(msg.sender);
        if (claimable_ == 0) revert NothingToClaim();
        _claimed[msg.sender] += claimable_;
        _tlx().transfer(msg.sender, claimable_);
        emit Claimed(msg.sender, claimable_);
    }

    function claimable(
        address account_
    ) public view override returns (uint256) {
        return vested(account_) - claimed(account_);
    }

    function vesting(address account_) public view override returns (uint256) {
        return _amounts[account_] - vested(account_);
    }

    function vested(address account_) public view override returns (uint256) {
        uint256 percent_ = (block.timestamp - _start).div(_duration);
        if (percent_ > 1e18) percent_ = 1e18;
        return _amounts[account_].mul(percent_);
    }

    function claimed(address account_) public view override returns (uint256) {
        return _claimed[account_];
    }

    function _tlx() internal view returns (ITlxToken) {
        return ITlxToken(IAddressProvider(_addressProvider).tlx());
    }
}
