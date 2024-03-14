// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ISynthetixHandler} from "./interfaces/ISynthetixHandler.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IFuturesMarketSettings} from "./interfaces/synthetix/IFuturesMarketSettings.sol";
import {IPerpsV2MarketData} from "./interfaces/synthetix/IPerpsV2MarketData.sol";
import {IPerpsV2MarketConsolidated} from "./interfaces/synthetix/IPerpsV2MarketConsolidated.sol";
import {IPerpsV2MarketBaseTypes} from "./interfaces/synthetix/IPerpsV2MarketBaseTypes.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

contract SynthetixHandler is ISynthetixHandler {
    using ScaledNumber for uint256;

    IPerpsV2MarketData internal immutable _perpsV2MarketData;
    IFuturesMarketSettings internal immutable _futuresMarketSettings;
    IAddressProvider internal immutable _addressProvider;

    uint256 internal constant _SLIPPAGE_TOLERANCE = 0.02e18; // 2%

    constructor(
        address addressProvider_,
        address perpsV2MarketData_,
        address futuresMarketSettings_
    ) {
        _perpsV2MarketData = IPerpsV2MarketData(perpsV2MarketData_);
        _addressProvider = IAddressProvider(addressProvider_);
        _futuresMarketSettings = IFuturesMarketSettings(futuresMarketSettings_);
    }

    /// @inheritdoc ISynthetixHandler
    function depositMargin(
        string calldata targetAsset_,
        uint256 amount_
    ) public override {
        IPerpsV2MarketConsolidated market_ = _market(targetAsset_);
        market_.transferMargin(int256(amount_));
    }

    /// @inheritdoc ISynthetixHandler
    function withdrawMargin(
        string calldata targetAsset_,
        uint256 amount_
    ) public override {
        _market(targetAsset_).transferMargin(-int256(amount_));
    }

    /// @inheritdoc ISynthetixHandler
    function submitLeverageUpdate(
        string calldata targetAsset_,
        uint256 leverage_,
        bool isLong_
    ) public override {
        uint256 marginAmount_ = remainingMargin(targetAsset_, address(this));
        if (marginAmount_ == 0) revert NoMargin();
        marginAmount_ -= _minKeeperFee(); // Subtract keeper fee
        uint256 assetPrice_ = assetPrice(targetAsset_);
        uint256 notionalValue_ = notionalValue(targetAsset_, address(this));
        notionalValue_ = notionalValue_.div(assetPrice_); // Convert to target units
        uint256 targetNotional_ = marginAmount_.mul(leverage_).div(assetPrice_);
        int256 sizeDelta_ = int256(targetNotional_) - int256(notionalValue_);
        if (!isLong_) sizeDelta_ = -sizeDelta_; // Invert if shorting
        IPerpsV2MarketConsolidated market_ = _market(targetAsset_);
        uint256 price_ = fillPrice(targetAsset_, sizeDelta_);

        if (isLong_) {
            price_ = price_.mul(1e18 + _SLIPPAGE_TOLERANCE);
        } else {
            price_ = price_.div(1e18 + _SLIPPAGE_TOLERANCE);
        }

        // This does not take into account the `dynamicFeeRate`, the `makerFee` and the `takerFee`
        // So the leverage we end up at will be slightly higher than our target
        // In practice, this is typically in the order of 0.2%, which is an order of magnitude smaller than our
        // rebalance threshold, so it is not an issue
        market_.submitOffchainDelayedOrder(sizeDelta_, price_);
    }

    /// @inheritdoc ISynthetixHandler
    function hasPendingLeverageUpdate(
        string calldata targetAsset_,
        address account_
    ) public view override returns (bool) {
        return _market(targetAsset_).delayedOrders(account_).sizeDelta != 0;
    }

    /// @inheritdoc ISynthetixHandler
    function hasOpenPosition(
        string calldata targetAsset_,
        address account_
    ) public view override returns (bool) {
        return _market(targetAsset_).positions(account_).size != 0;
    }

    /// @inheritdoc ISynthetixHandler
    function totalValue(
        string calldata targetAsset_,
        address account_
    ) public view override returns (uint256) {
        return remainingMargin(targetAsset_, account_);
    }

    /// @inheritdoc ISynthetixHandler
    function initialMargin(
        string calldata targetAsset_,
        address account_
    ) public view returns (uint256) {
        return _market(targetAsset_).positions(account_).margin;
    }

    /// @inheritdoc ISynthetixHandler
    function leverageDeviationFactor(
        string calldata targetAsset_,
        address account_,
        uint256 targetLeverage_
    ) public view returns (uint256) {
        uint256 initialNotional = initialMargin(targetAsset_, account_).mul(
            targetLeverage_
        );
        if (initialNotional == 0) return 0;
        uint256 currentNotional = notionalValue(targetAsset_, account_);
        return currentNotional.absSub(initialNotional).div(initialNotional);
    }

    /// @inheritdoc ISynthetixHandler
    function leverage(
        string calldata targetAsset_,
        address account_
    ) public view override returns (uint256) {
        uint256 notionalValue_ = notionalValue(targetAsset_, account_);
        uint256 marginRemaining_ = remainingMargin(targetAsset_, account_);
        if (marginRemaining_ == 0) revert NoMargin();
        return notionalValue_.div(marginRemaining_);
    }

    /// @inheritdoc ISynthetixHandler
    function notionalValue(
        string calldata targetAsset_,
        address account_
    ) public view override returns (uint256) {
        (int256 notionalValue_, bool invalid_) = _market(targetAsset_)
            .notionalValue(account_);
        if (invalid_) return 0;
        if (notionalValue_ < 0) return uint256(-notionalValue_);
        return uint256(notionalValue_);
    }

    /// @inheritdoc ISynthetixHandler
    function isLong(
        string calldata targetAsset_,
        address account_
    ) public view override returns (bool) {
        (int256 notionalValue_, bool invalid_) = _market(targetAsset_)
            .notionalValue(account_);
        if (invalid_) revert ErrorGettingIsLong();
        if (notionalValue_ == 0) revert ErrorGettingIsLong();
        return notionalValue_ > 0;
    }

    /// @inheritdoc ISynthetixHandler
    function remainingMargin(
        string calldata targetAsset_,
        address account_
    ) public view override returns (uint256) {
        (uint256 marginRemaining_, bool invalid_) = _market(targetAsset_)
            .remainingMargin(account_);
        if (invalid_) return 0;
        return marginRemaining_;
    }

    /// @inheritdoc ISynthetixHandler
    function fillPrice(
        string calldata targetAsset_,
        int256 sizeDelta_
    ) public view override returns (uint256) {
        (uint256 fillPrice_, bool invalid_) = _market(targetAsset_).fillPrice(
            sizeDelta_
        );
        if (invalid_) revert ErrorGettingFillPrice();
        return fillPrice_;
    }

    /// @inheritdoc ISynthetixHandler
    function isAssetSupported(
        string calldata targetAsset_
    ) public view override returns (bool) {
        try _perpsV2MarketData.marketDetailsForKey(_key(targetAsset_)) returns (
            IPerpsV2MarketData.MarketData memory
        ) {
            return true;
        } catch {
            return false;
        }
    }

    /// @inheritdoc ISynthetixHandler
    function assetPrice(
        string calldata targetAsset_
    ) public view override returns (uint256) {
        (uint256 assetPrice_, bool invalid_) = _market(targetAsset_)
            .assetPrice();
        if (invalid_) revert ErrorGettingAssetPrice();
        return assetPrice_;
    }

    function _pnl(
        string calldata targetAsset_,
        address account_
    ) internal view returns (int256) {
        (int256 pnl_, bool invalid_) = _market(targetAsset_).profitLoss(
            account_
        );
        if (invalid_) revert ErrorGettingPnl();
        return pnl_;
    }

    function _market(
        string calldata targetAsset_
    ) internal view returns (IPerpsV2MarketConsolidated) {
        IPerpsV2MarketData.MarketData memory marketData_ = _perpsV2MarketData
            .marketDetailsForKey(_key(targetAsset_));
        return IPerpsV2MarketConsolidated(marketData_.market);
    }

    function _minKeeperFee() internal view returns (uint256) {
        return _futuresMarketSettings.minKeeperFee();
    }

    function _key(
        string calldata targetAsset_
    ) internal pure returns (bytes32) {
        return bytes32(bytes(abi.encodePacked("s", targetAsset_, "PERP")));
    }
}
