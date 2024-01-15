// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";
import {Errors} from "./libraries/Errors.sol";

import {IStaker} from "./interfaces/IStaker.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract Staker is IStaker, Ownable {
    using ScaledNumber for uint256;

    IAddressProvider internal immutable _addressProvider;

    uint256 internal _rewardIntegral;
    mapping(address => uint256) internal _balances;
    mapping(address => uint256) internal _unstakeTimes;
    mapping(address => uint256) internal _usersRewardIntegral;
    mapping(address => uint256) internal _usersRewards;

    uint256 public immutable override unstakeDelay;
    address public immutable override rewardToken;

    uint256 public override totalStakeed;
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
        if (_hasPreparedUnstake(account_)) revert UnstakePrepared();

        _checkpoint(msg.sender);
        _addressProvider.tlx().transferFrom(msg.sender, address(this), amount_);
        _balances[account_] += amount_;
        totalStakeed += amount_;

        emit Stakeed(msg.sender, account_, amount_);
    }

    function prepareUnstake() public override {
        uint256 balance_ = _balances[msg.sender];
        if (balance_ == 0) revert ZeroBalance();
        if (_hasPreparedUnstake(msg.sender)) revert AlreadyPreparedUnstake();

        _checkpoint(msg.sender);
        _unstakeTimes[msg.sender] = block.timestamp + unstakeDelay;
        totalPrepared += balance_;

        emit PreparedUnstake(msg.sender);
    }

    function unstake() public override {
        unstakeFor(msg.sender);
    }

    function restake() public override {
        if (!_hasPreparedUnstake(msg.sender)) revert NoUnstakePrepared();

        _checkpoint(msg.sender);
        delete _unstakeTimes[msg.sender];
        totalPrepared -= _balances[msg.sender];

        emit Restakeed(msg.sender, _balances[msg.sender]);
    }

    function unstakeFor(address account_) public override {
        uint256 amount_ = _balances[msg.sender];
        if (amount_ == 0) revert ZeroBalance();
        uint256 unstakeTime_ = _unstakeTimes[msg.sender];
        if (unstakeTime_ == 0) revert NoUnstakePrepared();
        if (unstakeTime_ > block.timestamp) revert NotUnstakeed();

        _checkpoint(msg.sender);
        delete _balances[msg.sender];
        delete _unstakeTimes[msg.sender];
        totalStakeed -= amount_;
        totalPrepared -= amount_;

        _addressProvider.tlx().transfer(account_, amount_);

        emit Unstakeed(msg.sender, account_, amount_);
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

    function donateRewards(uint256 amount_) public override {
        if (amount_ == 0) revert ZeroAmount();
        uint256 divisor_ = totalStakeed - totalPrepared;
        if (divisor_ == 0) revert ZeroBalance();

        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount_);

        _rewardIntegral += amount_.div(divisor_);

        emit DonatedRewards(msg.sender, amount_);
    }

    function enableClaiming() public override onlyOwner {
        if (claimingEnabled) revert ClaimingAlreadyEnabled();

        claimingEnabled = true;
    }

    function claimable(
        address account_
    ) public view override returns (uint256) {
        return _usersRewards[account_] + _newRewards(account_);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function unstakeTime(
        address account
    ) public view override returns (uint256) {
        return _unstakeTimes[account];
    }

    function isUnstakeed(address account) public view override returns (bool) {
        if (!_hasPreparedUnstake(account)) return false;
        return _unstakeTimes[account] <= block.timestamp;
    }

    function symbol() public view override returns (string memory) {
        return string.concat("st", _addressProvider.tlx().symbol());
    }

    function name() public view override returns (string memory) {
        return string.concat("Staked ", _addressProvider.tlx().name());
    }

    function decimals() public view override returns (uint8) {
        return _addressProvider.tlx().decimals();
    }

    function _checkpoint(address account_) internal {
        _usersRewards[account_] += _newRewards(account_);
        _usersRewardIntegral[account_] = _rewardIntegral;
    }

    function _newRewards(address account_) internal view returns (uint256) {
        if (_hasPreparedUnstake(account_)) return 0;
        uint256 integral_ = _rewardIntegral - _usersRewardIntegral[account_];
        return integral_.mul(_balances[account_]);
    }

    function _hasPreparedUnstake(
        address account_
    ) internal view returns (bool) {
        return _unstakeTimes[account_] != 0;
    }
}
