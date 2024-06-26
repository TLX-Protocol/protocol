// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";
import {Errors} from "./libraries/Errors.sol";

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IGenesisLocker} from "./interfaces/IGenesisLocker.sol";
import {IRewardsStreaming} from "./interfaces/IRewardsStreaming.sol";

import {RewardsStreaming} from "./RewardsStreaming.sol";

contract GenesisLocker is IGenesisLocker, RewardsStreaming {
    using ScaledNumber for uint256;

    bool internal _shutdown;

    uint256 internal _amountAccounted;

    /// @inheritdoc IGenesisLocker
    uint256 public immutable override lockTime;
    /// @inheritdoc IGenesisLocker
    uint256 public override totalRewards;
    /// @inheritdoc IGenesisLocker
    uint256 public override rewardsStartTime;
    /// @inheritdoc IGenesisLocker
    mapping(address => uint256) public override unlockTime;

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

    /// @inheritdoc IGenesisLocker
    function lock(uint256 amount_) external {
        if (_shutdown || block.timestamp >= rewardsStartTime + lockTime)
            revert AlreadyShutdown();
        if (amount_ == 0) revert ZeroAmount();

        _checkpoint(msg.sender);

        _addressProvider.tlx().transferFrom(msg.sender, address(this), amount_);
        _balances[msg.sender] += amount_;
        unlockTime[msg.sender] = block.timestamp + lockTime;
        totalStaked += amount_;

        emit Locked(msg.sender, amount_);
    }

    /// @inheritdoc IRewardsStreaming
    function claim() external override {
        _claim();
    }

    /// @inheritdoc IGenesisLocker
    function shutdown() external onlyOwner {
        if (_shutdown) revert AlreadyShutdown();
        _globalCheckpoint();

        _shutdown = true;

        uint256 amount_ = totalRewards - _amountAccounted;
        emit Shutdown();
        if (amount_ == 0) return;
        IERC20(rewardToken).transfer(_addressProvider.treasury(), amount_);
    }

    /// @inheritdoc IGenesisLocker
    function migrate() external {
        migrateFor(msg.sender);
    }

    /// @inheritdoc IGenesisLocker
    function isShutdown() external view override returns (bool) {
        return _shutdown;
    }

    /// @inheritdoc IGenesisLocker
    function migrateFor(address receiver_) public {
        uint256 amount_ = _balances[msg.sender];
        if (amount_ == 0) revert ZeroAmount();
        if (receiver_ == address(0)) revert Errors.ZeroAddress();
        if (!_shutdown && unlockTime[msg.sender] > block.timestamp)
            revert NotUnlocked();

        _checkpoint(msg.sender);

        delete _balances[msg.sender];
        delete unlockTime[msg.sender];
        totalStaked -= amount_;

        _addressProvider.staker().stakeFor(amount_, receiver_);

        emit Migrated(msg.sender, receiver_, amount_);
    }

    /// @inheritdoc IRewardsStreaming
    function donateRewards(uint256 amount_) public override {
        if (msg.sender != address(_addressProvider.tlx()))
            revert Errors.NotAuthorized();
        if (amount_ == 0) revert ZeroAmount();
        if (totalRewards > 0) revert RewardsAlreadyDonated();

        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount_);
        totalRewards = amount_;
        rewardsStartTime = block.timestamp;
        emit DonatedRewards(msg.sender, amount_);
    }

    /// @inheritdoc IGenesisLocker
    function amountStreamed() public view override returns (uint256) {
        uint256 elapsed_ = block.timestamp - rewardsStartTime;
        if (elapsed_ >= lockTime) return totalRewards;
        return (elapsed_ * totalRewards) / lockTime;
    }

    /// @inheritdoc IRewardsStreaming
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
        if (divisor_ == 0) return;
        uint256 amount_ = amountStreamed() - _amountAccounted;
        _amountAccounted += amount_;
        _rewardIntegral += amount_.div(divisor_);
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
