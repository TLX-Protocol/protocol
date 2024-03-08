// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {TlxOwnable} from "./utils/TlxOwnable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";
import {Errors} from "./libraries/Errors.sol";

import {IBonding} from "./interfaces/IBonding.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IStaker} from "./interfaces/IStaker.sol";

contract Bonding is IBonding, TlxOwnable {
    using ScaledNumber for uint256;

    /// @inheritdoc IBonding
    uint256 public override totalTlxBonded;
    /// @inheritdoc IBonding
    bool public override isLive;

    IAddressProvider internal immutable _addressProvider;
    uint256 internal immutable _periodDecayMultiplier;
    uint256 internal immutable _periodDuration;

    uint256 internal _tlxPerSecond;
    uint256 internal _availableTlxCache;
    uint256 internal _lastUpdate;
    uint256 internal _lastDecayTimestamp;
    uint256 internal _baseForAllTlx;

    constructor(
        address addressProvider_,
        uint256 initialTlxPerSecond_,
        uint256 periodDecayMultiplier_,
        uint256 periodDuration_,
        uint256 baseForAllTlx_
    ) TlxOwnable(addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
        _tlxPerSecond = initialTlxPerSecond_;
        _periodDecayMultiplier = periodDecayMultiplier_;
        _periodDuration = periodDuration_;
        _lastDecayTimestamp = block.timestamp;
        _baseForAllTlx = baseForAllTlx_;
    }

    /// @inheritdoc IBonding
    function bond(
        address leveragedToken_,
        uint256 leveragedTokenAmount_,
        uint256 minTlxTokensReceived_
    ) external override returns (uint256) {
        // Check that the bonding is live
        if (!isLive) revert BondingNotLive();

        // Check that the leveraged token is valid
        if (!_isLeveragedToken(leveragedToken_)) {
            revert Errors.NotLeveragedToken();
        }
        if (!ILeveragedToken(leveragedToken_).isActive()) {
            revert InactiveToken();
        }

        // Transfer the leveraged token from the user to the POL
        IAddressProvider addressProvider_ = _addressProvider;
        IERC20(leveragedToken_).transferFrom(
            msg.sender,
            addressProvider_.pol(),
            leveragedTokenAmount_
        );

        // Update the cache
        _updateCache();

        // Calculate the amount of TLX tokens to send to the user
        uint256 availableTlx_ = _availableTlxCache;
        uint256 priceInBaseAsset_ = _priceInBaseAsset(leveragedToken_);
        uint256 baseAmount_ = leveragedTokenAmount_.mul(priceInBaseAsset_);
        uint256 tlxAmount_ = baseAmount_.mul(_exchangeRate(availableTlx_));
        if (tlxAmount_ < minTlxTokensReceived_) revert MinTlxNotReached();
        if (tlxAmount_ > availableTlx_) revert ExceedsAvailable();
        totalTlxBonded += tlxAmount_;

        // Transfer the TLX tokens to the user
        IStaker staker_ = addressProvider_.staker();
        addressProvider_.tlx().approve(address(staker_), tlxAmount_);
        staker_.stakeFor(tlxAmount_, msg.sender);

        // Emit the event
        emit Bonded(
            msg.sender,
            leveragedToken_,
            leveragedTokenAmount_,
            tlxAmount_
        );
        return tlxAmount_;
    }

    /// @inheritdoc IBonding
    function setBaseForAllTlx(
        uint256 baseForAllTlx_
    ) external override onlyOwner {
        if (!isLive) revert BondingNotLive();
        _updateCache();
        _baseForAllTlx = baseForAllTlx_;
        emit BaseForAllTlxSet(baseForAllTlx_);
    }

    /// @inheritdoc IBonding
    function launch() external override onlyOwner {
        if (isLive) revert BondingAlreadyLive();
        isLive = true;
        _lastUpdate = block.timestamp;
    }

    /// @inheritdoc IBonding
    function migrate() external override onlyOwner {
        IAddressProvider addressProvider_ = _addressProvider;
        address bonding_ = address(addressProvider_.bonding());
        if (address(bonding_) == address(this)) revert Errors.SameAsCurrent();
        IERC20 tlx_ = addressProvider_.tlx();
        uint256 balance_ = tlx_.balanceOf(address(this));
        if (balance_ == 0) revert AlreadyMigrated();
        tlx_.transfer(bonding_, balance_);
        emit Migrated(balance_);
    }

    /// @inheritdoc IBonding
    function availableTlx() public view override returns (uint256) {
        if (!isLive) return 0;

        uint256 nextDecay_ = _lastDecayTimestamp + _periodDuration;
        return
            _tlxInRange(
                _lastUpdate,
                block.timestamp,
                _tlxPerSecond,
                nextDecay_
            ) +
            _availableTlxCache -
            totalTlxBonded;
    }

    /// @inheritdoc IBonding
    function exchangeRate() public view override returns (uint256) {
        return _exchangeRate(availableTlx());
    }

    function _updateCache() internal {
        uint256 nextDecay_ = _lastDecayTimestamp + _periodDuration;

        // We are still within the current period
        if (block.timestamp < nextDecay_) {
            uint256 time_ = block.timestamp - _lastUpdate;
            _availableTlxCache += time_ * _tlxPerSecond;
            _lastUpdate = block.timestamp;
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
            _updateCache();
        }
    }

    function _exchangeRate(
        uint256 availableTlx_
    ) internal view returns (uint256) {
        return availableTlx_.div(_baseForAllTlx);
    }

    function _tlxInRange(
        uint256 rangeStart_,
        uint256 rangeEnd_,
        uint256 tlxPerSecond_,
        uint256 nextDecay_
    ) internal view returns (uint256) {
        if (rangeStart_ == rangeEnd_) return 0;
        uint256 time_ = rangeEnd_ - rangeStart_;
        if (rangeEnd_ > nextDecay_) {
            time_ = nextDecay_ - rangeStart_;
            return
                time_ *
                tlxPerSecond_ +
                _tlxInRange(
                    nextDecay_,
                    rangeEnd_,
                    tlxPerSecond_.mul(_periodDecayMultiplier),
                    nextDecay_ + _periodDuration
                );
        }
        return time_ * tlxPerSecond_;
    }

    function _isLeveragedToken(address token_) internal view returns (bool) {
        return
            _addressProvider.leveragedTokenFactory().isLeveragedToken(token_);
    }

    function _priceInBaseAsset(address token_) internal view returns (uint256) {
        return ILeveragedToken(token_).exchangeRate();
    }
}
