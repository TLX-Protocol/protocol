// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {ILocker} from "./interfaces/ILocker.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract Locker is ILocker {
    using ScaledNumber for uint256;

    address internal immutable _addressProvider;

    uint256 internal _rewardIntegral;
    mapping(address => uint256) internal _balances;
    mapping(address => uint256) internal _unlockTimes;
    mapping(address => uint256) internal _usersRewardIntegral;
    mapping(address => uint256) internal _usersRewards;

    uint256 public immutable override unlockDelay;
    address public immutable override rewardToken;

    uint256 public override totalLocked;
    uint256 public override totalPrepared;

    constructor(
        address addressProvider_,
        uint256 unlockDelay_,
        address rewardToken_
    ) {
        _addressProvider = addressProvider_;
        unlockDelay = unlockDelay_;
        rewardToken = rewardToken_;
    }

    function lock(uint256 amount_) public override {
        lockFor(amount_, msg.sender);
    }

    function lockFor(uint256 amount_, address account_) public override {
        if (amount_ == 0) revert ZeroAmount();
        if (account_ == address(0)) revert ZeroAddress();
        if (_hasPreparedUnlock(account_)) revert UnlockPrepared();

        _checkpoint(msg.sender);
        _tlx().transferFrom(msg.sender, address(this), amount_);
        _balances[account_] += amount_;
        totalLocked += amount_;

        emit Locked(msg.sender, account_, amount_);
    }

    function prepareUnlock() public override {
        uint256 balance_ = _balances[msg.sender];
        if (balance_ == 0) revert ZeroBalance();
        if (_hasPreparedUnlock(msg.sender)) revert AlreadyPreparedUnlock();

        _checkpoint(msg.sender);
        _unlockTimes[msg.sender] = block.timestamp + unlockDelay;
        totalPrepared += balance_;

        emit PreparedUnlock(msg.sender);
    }

    function unlock() public override {
        unlockFor(msg.sender);
    }

    function relock() public override {
        if (!_hasPreparedUnlock(msg.sender)) revert NoUnlockPrepared();

        _checkpoint(msg.sender);
        delete _unlockTimes[msg.sender];
        totalPrepared -= _balances[msg.sender];

        emit Relocked(msg.sender, _balances[msg.sender]);
    }

    function unlockFor(address account_) public override {
        uint256 amount_ = _balances[msg.sender];
        if (amount_ == 0) revert ZeroBalance();
        uint256 unlockTime_ = _unlockTimes[msg.sender];
        if (unlockTime_ == 0) revert NoUnlockPrepared();
        if (unlockTime_ > block.timestamp) revert NotUnlocked();

        _checkpoint(msg.sender);
        delete _balances[msg.sender];
        delete _unlockTimes[msg.sender];
        totalLocked -= amount_;
        totalPrepared -= amount_;

        _tlx().transfer(account_, amount_);

        emit Unlocked(msg.sender, account_, amount_);
    }

    function claim() public override {
        _checkpoint(msg.sender);

        uint256 amount_ = _usersRewards[msg.sender];
        if (amount_ == 0) return;

        delete _usersRewards[msg.sender];
        IERC20(rewardToken).transfer(msg.sender, amount_);

        emit Claimed(msg.sender, amount_);
    }

    function donateRewards(uint256 amount_) public override {
        if (amount_ == 0) revert ZeroAmount();
        uint256 divisor_ = totalLocked - totalPrepared;
        if (divisor_ == 0) revert ZeroBalance();

        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount_);

        _rewardIntegral += amount_.div(divisor_);

        emit DonatedRewards(msg.sender, amount_);
    }

    function claimable(
        address account_
    ) public view override returns (uint256) {
        return _usersRewards[account_] + _newRewards(account_);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function unlockTime(
        address account
    ) public view override returns (uint256) {
        return _unlockTimes[account];
    }

    function isUnlocked(address account) public view override returns (bool) {
        if (!_hasPreparedUnlock(account)) return false;
        return _unlockTimes[account] <= block.timestamp;
    }

    function symbol() public view override returns (string memory) {
        return string(abi.encodePacked("st", _tlx().symbol()));
    }

    function name() public view override returns (string memory) {
        return string(abi.encodePacked("Staked ", _tlx().name()));
    }

    function decimals() public view override returns (uint8) {
        return _tlx().decimals();
    }

    function _checkpoint(address account_) internal {
        _usersRewards[account_] += _newRewards(account_);
        _usersRewardIntegral[account_] = _rewardIntegral;
    }

    function _newRewards(address account_) internal view returns (uint256) {
        if (_hasPreparedUnlock(account_)) return 0;
        uint256 integral_ = _rewardIntegral - _usersRewardIntegral[account_];
        return integral_.mul(_balances[account_]);
    }

    function _tlx() internal view returns (IERC20Metadata) {
        return IERC20Metadata(IAddressProvider(_addressProvider).tlx());
    }

    function _hasPreparedUnlock(address account_) internal view returns (bool) {
        return _unlockTimes[account_] != 0;
    }
}
