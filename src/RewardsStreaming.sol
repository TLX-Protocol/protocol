// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";
import {Errors} from "./libraries/Errors.sol";

import {IRewardsStreaming} from "./interfaces/IRewardsStreaming.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

abstract contract RewardsStreaming is IRewardsStreaming, Ownable {
    using ScaledNumber for uint256;

    IAddressProvider internal immutable _addressProvider;

    uint256 internal _rewardIntegral;
    mapping(address => uint256) internal _balances;
    mapping(address => uint256) internal _usersRewardIntegral;
    mapping(address => uint256) internal _usersRewards;

    address public immutable override rewardToken;

    uint256 public override totalStaked;

    constructor(address addressProvider_, address rewardToken_) {
        _addressProvider = IAddressProvider(addressProvider_);
        rewardToken = rewardToken_;
    }

    function claimable(
        address account_
    ) public view override returns (uint256) {
        return
            _usersRewards[account_] + _newRewards(account_, _latestIntegral());
    }

    function balanceOf(
        address account_
    ) public view override returns (uint256) {
        return _balances[account_];
    }

    function activeBalanceOf(
        address account
    ) public view virtual override returns (uint256);

    function decimals() public view override returns (uint8) {
        return _addressProvider.tlx().decimals();
    }

    function _checkpoint(address account_) internal {
        _globalCheckpoint();
        _usersRewards[account_] += _newRewards(account_, _rewardIntegral);
        _usersRewardIntegral[account_] = _rewardIntegral;
    }

    function _claim() internal {
        _checkpoint(msg.sender);

        uint256 amount_ = _usersRewards[msg.sender];
        if (amount_ == 0) return;

        delete _usersRewards[msg.sender];
        IERC20(rewardToken).transfer(msg.sender, amount_);

        emit Claimed(msg.sender, amount_);
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
