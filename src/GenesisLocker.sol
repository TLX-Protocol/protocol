// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";
import {Errors} from "./libraries/Errors.sol";

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

import {BaseStaker} from "./BaseStaker.sol";

contract GenesisLocker is BaseStaker {
    using ScaledNumber for uint256;

    uint256 public immutable streamingPeriod;
    uint256 public donatedAmount;
    uint256 public donatedAt;
    uint256 public amountAccounted;

    error RewardsAlreadyDonated();

    constructor(
        address addressProvider_,
        uint256 unlockDelay_,
        address rewardToken_,
        uint256 streamingPeriod_
    ) BaseStaker(addressProvider_, unlockDelay_, rewardToken_) {
        streamingPeriod = streamingPeriod_;
    }

    function donateRewards(uint256 amount_) public override {
        if (amount_ == 0) revert ZeroAmount();
        if (donatedAmount > 0) revert RewardsAlreadyDonated();
        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount_);
        donatedAmount = amount_;
        donatedAt = block.timestamp;
        emit DonatedRewards(msg.sender, amount_);
    }

    function amountStreamed() public view returns (uint256) {
        uint256 elapsed = block.timestamp - donatedAt;
        if (elapsed >= streamingPeriod) return donatedAmount;
        return (elapsed * donatedAmount) / streamingPeriod;
    }

    function _globalCheckpoint() internal virtual override {
        uint256 divisor_ = totalStaked - totalPrepared;
        if (divisor_ > 0) {
            uint256 amount_ = amountStreamed() - amountAccounted;
            amountAccounted += amount_;
            _rewardIntegral += amount_.div(divisor_);
        }
    }

    function _latestIntegral()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        uint256 divisor_ = totalStaked - totalPrepared;
        if (divisor_ == 0) return 0;
        uint256 amount_ = amountStreamed() - amountAccounted;
        return _rewardIntegral + amount_.div(divisor_);
    }
}
