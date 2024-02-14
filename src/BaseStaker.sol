// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";
import {Errors} from "./libraries/Errors.sol";
import {Withdrawals} from "./libraries/Withdrawals.sol";

import {IBaseStaker} from "./interfaces/IBaseStaker.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

abstract contract BaseStaker is IBaseStaker, Ownable {
    using ScaledNumber for uint256;
    using Withdrawals for Withdrawals.UserWithdrawals;

    IAddressProvider internal immutable _addressProvider;

    uint256 internal _rewardIntegral;
    mapping(address => uint256) internal _balances;
    mapping(address => Withdrawals.UserWithdrawals) internal _queuedWithdrawals;
    mapping(address => uint256) internal _usersRewardIntegral;
    mapping(address => uint256) internal _usersRewards;

    uint256 public immutable override unstakeDelay;
    address public immutable override rewardToken;

    uint256 public override totalStaked;
    uint256 public override totalPrepared;
    bool public override claimingEnabled;

    constructor(
        address addressProvider_,
        uint256 unstakeDelay_,
        address rewardToken_
    ) {
        _addressProvider = IAddressProvider(addressProvider_);
        unstakeDelay = unstakeDelay_;
        rewardToken = rewardToken_;
    }

    function stake(uint256 amount_) public override {
        stakeFor(amount_, msg.sender);
    }

    function stakeFor(uint256 amount_, address account_) public override {
        if (amount_ == 0) revert ZeroAmount();
        if (account_ == address(0)) revert Errors.ZeroAddress();

        _checkpoint(account_);

        _addressProvider.tlx().transferFrom(msg.sender, address(this), amount_);
        _balances[account_] += amount_;
        totalStaked += amount_;

        emit Staked(msg.sender, account_, amount_);
    }

    function prepareUnstake(
        uint256 amount_
    ) public override returns (uint256 id) {
        if (amount_ == 0) revert ZeroAmount();
        if (activeBalanceOf(msg.sender) < amount_) revert InsufficientBalance();

        _checkpoint(msg.sender);
        id = _queuedWithdrawals[msg.sender].queue(
            amount_,
            block.timestamp + unstakeDelay
        );
        totalPrepared += amount_;

        emit PreparedUnstake(msg.sender);
    }

    function unstake(uint256 withdrawalId_) public override {
        unstakeFor(msg.sender, withdrawalId_);
    }

    function restake(uint256 withdrawalId_) public override {
        _checkpoint(msg.sender);

        Withdrawals.UserWithdrawal memory withdrawal_ = _queuedWithdrawals[
            msg.sender
        ].remove(withdrawalId_);
        totalPrepared -= withdrawal_.amount;

        emit Restaked(msg.sender, withdrawal_.amount);
    }

    function unstakeFor(
        address account_,
        uint256 withdrawalId_
    ) public override {
        _checkpoint(msg.sender);

        Withdrawals.UserWithdrawal memory withdrawal_ = _queuedWithdrawals[
            msg.sender
        ].remove(withdrawalId_);
        uint256 unstakeTime_ = withdrawal_.unlockTime;
        if (unstakeTime_ > block.timestamp) revert NotUnstaked();

        uint256 amount_ = withdrawal_.amount;

        _balances[msg.sender] -= amount_;
        totalStaked -= amount_;
        totalPrepared -= amount_;

        _addressProvider.tlx().transfer(account_, amount_);

        emit Unstaked(msg.sender, account_, amount_);
    }

    function claim() public override {
        if (!claimingEnabled) revert ClaimingNotEnabled();

        _checkpoint(msg.sender);

        uint256 amount_ = _usersRewards[msg.sender];
        if (amount_ == 0) return;

        delete _usersRewards[msg.sender];
        IERC20(rewardToken).transfer(msg.sender, amount_);

        emit Claimed(msg.sender, amount_);
    }

    function enableClaiming() public override onlyOwner {
        if (claimingEnabled) revert ClaimingAlreadyEnabled();

        claimingEnabled = true;
    }

    function claimable(
        address account_
    ) public view override returns (uint256) {
        return
            _usersRewards[account_] + _newRewards(account_, _latestIntegral());
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function activeBalanceOf(address account) public view returns (uint256) {
        return _balances[account] - _queuedWithdrawals[account].totalQueued;
    }

    function unstakeTime(
        address account,
        uint256 withdrawalId
    ) public view override returns (uint256) {
        (Withdrawals.UserWithdrawal memory withdrawal_, ) = _queuedWithdrawals[
            account
        ].tryGet(withdrawalId);
        return withdrawal_.unlockTime;
    }

    function isUnstaked(
        address account,
        uint256 withdrawalId
    ) public view override returns (bool) {
        (
            Withdrawals.UserWithdrawal memory withdrawal_,
            bool exists_
        ) = _queuedWithdrawals[account].tryGet(withdrawalId);
        return exists_ && withdrawal_.unlockTime <= block.timestamp;
    }

    function decimals() public view override returns (uint8) {
        return _addressProvider.tlx().decimals();
    }

    function _checkpoint(address account_) internal {
        _globalCheckpoint();
        _usersRewards[account_] += _newRewards(account_, _rewardIntegral);
        _usersRewardIntegral[account_] = _rewardIntegral;
    }

    function _globalCheckpoint() internal virtual {}

    function _newRewards(
        address account_,
        uint256 rewardIntegral_
    ) internal view returns (uint256) {
        uint256 integral_ = rewardIntegral_ - _usersRewardIntegral[account_];
        return integral_.mul(activeBalanceOf(account_));
    }

    function _latestIntegral() internal view virtual returns (uint256) {
        return _rewardIntegral;
    }
}
