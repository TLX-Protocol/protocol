// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {IStaker} from "./interfaces/IStaker.sol";
import {BaseStaker} from "./BaseStaker.sol";

contract Staker is IStaker, BaseStaker {
    using ScaledNumber for uint256;

    constructor(
        address addressProvider_,
        uint256 unstakeDelay_,
        address rewardToken_
    ) BaseStaker(addressProvider_, unstakeDelay_, rewardToken_) {}

    function donateRewards(uint256 amount_) public override {
        if (amount_ == 0) revert ZeroAmount();
        uint256 divisor_ = totalStaked - totalPrepared;
        if (divisor_ == 0) revert ZeroBalance();

        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount_);

        _rewardIntegral += amount_.div(divisor_);

        emit DonatedRewards(msg.sender, amount_);
    }

    function symbol() public view override returns (string memory) {
        return string.concat("st", _addressProvider.tlx().symbol());
    }

    function name() public view override returns (string memory) {
        return string.concat("Staked ", _addressProvider.tlx().name());
    }
}
