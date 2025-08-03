// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {AutomationCompatibleInterface} from "chainlink/src/v0.8/automation/AutomationCompatible.sol";

import {ScaledNumber} from "../libraries/ScaledNumber.sol";

import {TlxOwnable} from "../utils/TlxOwnable.sol";

import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IRewards} from "../interfaces/velodrome/IRewards.sol";

contract VelodromeVoterAutomation is AutomationCompatibleInterface, TlxOwnable {
    using ScaledNumber for uint256;
    using SafeERC20 for IERC20;

    IAddressProvider internal immutable _addressProvider;
    IRewards internal immutable _tlxEthRewards;
    uint256 internal immutable _periodDecayMultiplier;
    uint256 internal immutable _periodDuration;

    uint256 internal _tlxPerSecond;
    uint256 internal _availableTlxCache;
    uint256 internal _lastUpdate;
    uint256 internal _lastDecayTimestamp;
    uint256 internal _lastIncentivesTimestamp;
    uint256 internal _incentivesPaid;

    error CanNotRun();

    constructor(
        address addressProvider_,
        uint256 initialTlxPerSecond_,
        uint256 periodDecayMultiplier_,
        uint256 periodDuration_,
        uint256 lastIncentivesTimestamp_,
        address tlxEthRewards_,
        uint256 inflationStartTimestamp_,
        uint256 incentivesPaid_
    ) TlxOwnable(addressProvider_) {
        // Set the initial values
        _addressProvider = IAddressProvider(addressProvider_);
        _tlxEthRewards = IRewards(tlxEthRewards_);
        _tlxPerSecond = initialTlxPerSecond_;
        _periodDecayMultiplier = periodDecayMultiplier_;
        _periodDuration = periodDuration_;
        _lastIncentivesTimestamp = lastIncentivesTimestamp_;

        // Start inflation
        _lastUpdate = inflationStartTimestamp_;
        _lastDecayTimestamp = inflationStartTimestamp_;
        _incentivesPaid = incentivesPaid_;

        // Approvals
        IAddressProvider(addressProvider_).tlx().approve(
            tlxEthRewards_,
            type(uint256).max
        );
    }

    function performUpkeep(bytes calldata) external override {
        if (!_canRun()) revert CanNotRun();
        uint256 nextIncentiveTimestamp_ = _nextIncentivesTimestamp();
        _updateCache(nextIncentiveTimestamp_);
        address tlx_ = address(_addressProvider.tlx());
        uint256 incentives_ = _availableTlxCache - _incentivesPaid;
        _tlxEthRewards.notifyRewardAmount(tlx_, incentives_);
        _lastIncentivesTimestamp = nextIncentiveTimestamp_;
        _incentivesPaid = _availableTlxCache;
    }

    function recoverTokens(address token_, address to_) external onlyOwner {
        uint256 balance_ = IERC20(token_).balanceOf(address(this));
        IERC20(token_).safeTransfer(to_, balance_);
    }

    function checkUpkeep(
        bytes calldata
    ) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = _canRun();
        return (upkeepNeeded, "");
    }

    function _updateCache(uint256 updateTime_) internal {
        uint256 nextDecay_ = _lastDecayTimestamp + _periodDuration;

        // We are still within the current period
        if (updateTime_ < nextDecay_) {
            uint256 time_ = updateTime_ - _lastUpdate;
            _availableTlxCache += time_ * _tlxPerSecond;
            _lastUpdate = updateTime_;
            return;
        }
        // We are in a new period
        else {
            // Update the cache with the remaining time in the current period
            uint256 periodTime_ = nextDecay_ - _lastUpdate;
            uint256 tlxPerSecond_ = _tlxPerSecond;
            _availableTlxCache += periodTime_ * tlxPerSecond_;
            _tlxPerSecond = tlxPerSecond_.mul(_periodDecayMultiplier);
            _lastDecayTimestamp = nextDecay_;
            _lastUpdate = nextDecay_;

            // Update the cache with the remaining time in the new period(s)
            _updateCache(updateTime_);
        }
    }

    function _canRun() internal view returns (bool) {
        return
            block.timestamp > _lastIncentivesTimestamp &&
            block.timestamp < _nextIncentivesTimestamp();
    }

    function _nextIncentivesTimestamp() internal view returns (uint256) {
        return _lastIncentivesTimestamp + 7 days;
    }
}
