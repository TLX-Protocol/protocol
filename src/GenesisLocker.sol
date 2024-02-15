// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";
import {Errors} from "./libraries/Errors.sol";

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IGenesisLocker} from "./interfaces/IGenesisLocker.sol";
import {IRewardsStreaming} from "./interfaces/IRewardsStreaming.sol";

import {RewardsStreaming} from "./RewardsStreaming.sol";

contract GenesisLocker is IGenesisLocker, RewardsStreaming {
    using ScaledNumber for uint256;

    uint256 internal _amountAccounted;

    uint256 public immutable override lockTime;
    uint256 public override totalRewards;
    uint256 public override rewardsStartTime;
    mapping(address => uint256) public override unlockTime;

    error RewardsAlreadyDonated();

    constructor(
        address addressProvider_,
        uint256 lockTime_,
        address rewardToken_
    ) RewardsStreaming(addressProvider_, rewardToken_) {
        lockTime = lockTime_;

        // Approving the staker to transfer TLX
        address staker_ = address(_addressProvider.staker());
        if (staker_ == address(0)) revert StakerNotDeployed();
        _addressProvider.tlx().approve(staker_, type(uint256).max);
    }

    function lock(uint256 amount_) external {
        if (amount_ == 0) revert ZeroAmount();

        _checkpoint(msg.sender);

        _addressProvider.tlx().transferFrom(msg.sender, address(this), amount_);
        _balances[msg.sender] += amount_;
        unlockTime[msg.sender] = block.timestamp + lockTime;
        totalStaked += amount_;

        emit Locked(msg.sender, amount_);
    }

    function claim() external override {
        _claim();
    }

    function migrate() external {
        migrateFor(msg.sender);
    }

    function migrateFor(address receiver_) public {
        uint256 amount_ = _balances[msg.sender];
        if (amount_ == 0) revert ZeroAmount();
        if (receiver_ == address(0)) revert Errors.ZeroAddress();
        if (unlockTime[msg.sender] > block.timestamp) revert NotUnlocked();

        _checkpoint(msg.sender);

        delete _balances[msg.sender];
        delete unlockTime[msg.sender];

        _addressProvider.staker().stakeFor(amount_, receiver_);

        emit Migrated(msg.sender, receiver_, amount_);
    }

    function donateRewards(uint256 amount_) public override {
        if (amount_ == 0) revert ZeroAmount();
        if (totalRewards > 0) revert RewardsAlreadyDonated();
        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount_);
        totalRewards = amount_;
        rewardsStartTime = block.timestamp;
        emit DonatedRewards(msg.sender, amount_);
    }

    function amountStreamed() public view returns (uint256) {
        uint256 elapsed = block.timestamp - rewardsStartTime;
        if (elapsed >= lockTime) return totalRewards;
        return (elapsed * totalRewards) / lockTime;
    }

    function activeBalanceOf(
        address account_
    )
        public
        view
        override(IRewardsStreaming, RewardsStreaming)
        returns (uint256)
    {
        return _balances[account_];
    }

    function _globalCheckpoint() internal virtual override {
        uint256 divisor_ = totalStaked;
        if (divisor_ > 0) {
            uint256 amount_ = amountStreamed() - _amountAccounted;
            _amountAccounted += amount_;
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
        uint256 divisor_ = totalStaked;
        if (divisor_ == 0) return 0;
        uint256 amount_ = amountStreamed() - _amountAccounted;
        return _rewardIntegral + amount_.div(divisor_);
    }
}
