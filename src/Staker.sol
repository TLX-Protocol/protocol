// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";
import {Errors} from "./libraries/Errors.sol";

import {IStaker} from "./interfaces/IStaker.sol";
import {IRewardsStreaming} from "./interfaces/IRewardsStreaming.sol";
import {RewardsStreaming} from "./RewardsStreaming.sol";
import {Unstakes} from "./libraries/Unstakes.sol";

contract Staker is IStaker, RewardsStreaming {
    using ScaledNumber for uint256;
    using Unstakes for Unstakes.UserUnstakes;

    mapping(address => Unstakes.UserUnstakes) internal _queuedUnstakes;
    /// @inheritdoc IStaker
    uint256 public immutable override unstakeDelay;
    /// @inheritdoc IStaker
    uint256 public override totalPrepared;
    /// @inheritdoc IStaker
    bool public override claimingEnabled;

    constructor(
        address addressProvider_,
        uint256 unstakeDelay_,
        address rewardToken_
    ) RewardsStreaming(addressProvider_, rewardToken_) {
        unstakeDelay = unstakeDelay_;
    }

    /// @inheritdoc IRewardsStreaming
    function donateRewards(uint256 amount_) external override {
        if (amount_ == 0) revert ZeroAmount();
        uint256 divisor_ = totalStaked - totalPrepared;
        if (divisor_ == 0) revert ZeroBalance();

        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount_);

        _rewardIntegral += amount_.div(divisor_);

        emit DonatedRewards(msg.sender, amount_);
    }

    /// @inheritdoc IRewardsStreaming
    function claim() external override {
        if (!claimingEnabled) revert ClaimingNotEnabled();

        _claim();
    }

    /// @inheritdoc IStaker
    function stake(uint256 amount_) external override {
        stakeFor(amount_, msg.sender);
    }

    /// @inheritdoc IStaker
    function listQueuedUnstakes(
        address account
    ) external view returns (Unstakes.UserUnstakeData[] memory unstakes) {
        return _queuedUnstakes[account].list();
    }

    /// @inheritdoc IStaker
    function stakeFor(uint256 amount_, address account_) public override {
        if (amount_ == 0) revert ZeroAmount();
        if (account_ == address(0)) revert Errors.ZeroAddress();

        _checkpoint(account_);

        _addressProvider.tlx().transferFrom(msg.sender, address(this), amount_);
        _balances[account_] += amount_;
        totalStaked += amount_;

        emit Staked(msg.sender, account_, amount_);
    }

    /// @inheritdoc IStaker
    function prepareUnstake(
        uint256 amount_
    ) public override returns (uint256 id) {
        if (amount_ == 0) revert ZeroAmount();
        if (activeBalanceOf(msg.sender) < amount_) revert InsufficientBalance();

        _checkpoint(msg.sender);
        id = _queuedUnstakes[msg.sender].queue(
            amount_,
            block.timestamp + unstakeDelay
        );
        totalPrepared += amount_;

        emit PreparedUnstake(msg.sender, amount_, id);
    }

    /// @inheritdoc IStaker
    function enableClaiming() public override onlyOwner {
        if (claimingEnabled) revert ClaimingAlreadyEnabled();

        claimingEnabled = true;
    }

    /// @inheritdoc IStaker
    function unstake(uint256 withdrawalId_) public override {
        unstakeFor(msg.sender, withdrawalId_);
    }

    /// @inheritdoc IStaker
    function restake(uint256 withdrawalId_) public override {
        _checkpoint(msg.sender);

        Unstakes.UserUnstake memory withdrawal_ = _queuedUnstakes[msg.sender]
            .remove(withdrawalId_);
        totalPrepared -= withdrawal_.amount;

        emit Restaked(msg.sender, withdrawal_.amount);
    }

    /// @inheritdoc IStaker
    function unstakeFor(
        address account_,
        uint256 withdrawalId_
    ) public override {
        _checkpoint(msg.sender);

        Unstakes.UserUnstake memory withdrawal_ = _queuedUnstakes[msg.sender]
            .remove(withdrawalId_);
        uint256 unstakeTime_ = withdrawal_.unstakeTime;
        if (unstakeTime_ > block.timestamp) revert NotUnstaked();

        uint256 amount_ = withdrawal_.amount;

        _balances[msg.sender] -= amount_;
        totalStaked -= amount_;
        totalPrepared -= amount_;

        _addressProvider.tlx().transfer(account_, amount_);

        emit Unstaked(msg.sender, account_, amount_);
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
        return _balances[account_] - _queuedUnstakes[account_].totalQueued;
    }

    /// @inheritdoc IStaker
    function symbol() public view override returns (string memory) {
        return string.concat("st", _addressProvider.tlx().symbol());
    }

    /// @inheritdoc IStaker
    function name() public view override returns (string memory) {
        return string.concat("Staked ", _addressProvider.tlx().name());
    }

    function _latestIntegral()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return _rewardIntegral;
    }
}
