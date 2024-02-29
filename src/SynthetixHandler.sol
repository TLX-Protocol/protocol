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

    uint256 internal constant _SLIPPAGE_TOLERANCE = 0.002e18; // 0.2%

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
    function depositMargin(address market_, uint256 amount_) public override {
        _addressProvider.baseAsset().approve(market_, amount_);
        IPerpsV2MarketConsolidated(market_).transferMargin(int256(amount_));
    }

    /// @inheritdoc ISynthetixHandler
    function withdrawMargin(address market_, uint256 amount_) public override {
        IPerpsV2MarketConsolidated(market_).transferMargin(-int256(amount_));
    }

    /// @inheritdoc ISynthetixHandler
    function submitLeverageUpdate(
        address market_,
        uint256 leverage_,
        bool isLong_
    ) public override {
        uint256 marginAmount_ = remainingMargin(market_, address(this));
        if (marginAmount_ == 0) revert NoMargin();
        marginAmount_ -= _minKeeperFee(); // Subtract keeper fee
        uint256 assetPrice_ = assetPrice(market_);
        uint256 notionalValue_ = notionalValue(market_, address(this));
        notionalValue_ = notionalValue_.div(assetPrice_); // Convert to target units
        uint256 targetNotional_ = marginAmount_.mul(leverage_).div(assetPrice_);
        int256 sizeDelta_ = int256(targetNotional_) - int256(notionalValue_);
        if (!isLong_) sizeDelta_ = -sizeDelta_; // Invert if shorting
        uint256 price_ = fillPrice(market_, sizeDelta_);

        if (isLong_) {
            price_ = price_.mul(1e18 + _SLIPPAGE_TOLERANCE);
        } else {
            price_ = price_.div(1e18 + _SLIPPAGE_TOLERANCE);
        }

        // This does not take into account the `dynamicFeeRate`, the `makerFee` and the `takerFee`
        // So the leverage we end up at will be slightly higher than our target
        // In practice, this is typically in the order of 0.2%, which is an order of magnitude smaller than our
        // rebalance threshold, so it is not an issue
        IPerpsV2MarketConsolidated(market_).submitOffchainDelayedOrder(
            sizeDelta_,
            price_
        );
    }

    /// @inheritdoc ISynthetixHandler
    function cancelLeverageUpdate(address market_) public override {
        IPerpsV2MarketConsolidated(market_).cancelOffchainDelayedOrder(
            address(this)
        );
    }

    /// @inheritdoc ISynthetixHandler
    function market(
        string calldata targetAsset_
    ) external view returns (address) {
        IPerpsV2MarketData.MarketData memory marketData_ = _perpsV2MarketData
            .marketDetailsForKey(_key(targetAsset_));
        return marketData_.market;
    }

    /// @inheritdoc ISynthetixHandler
    function hasPendingLeverageUpdate(
        address market_,
        address account_
    ) public view override returns (bool) {
        return
            IPerpsV2MarketConsolidated(market_)
                .delayedOrders(account_)
                .sizeDelta != 0;
    }

    /// @inheritdoc ISynthetixHandler
    function hasOpenPosition(
        address market_,
        address account_
    ) public view override returns (bool) {
        return notionalValue(market_, account_) != 0;
    }

    /// @inheritdoc ISynthetixHandler
    function totalValue(
        address market_,
        address account_
    ) public view override returns (uint256) {
        uint256 remainingMargin_ = remainingMargin(market_, account_);
        if (!hasOpenPosition(market_, account_)) return remainingMargin_;
        int256 pnl_ = _pnl(market_, account_);
        return uint256(int256(remainingMargin_) + pnl_);
    }

    /// @inheritdoc ISynthetixHandler
    function initialMargin(
        address market_,
        address account_
    ) public view returns (uint256) {
        return IPerpsV2MarketConsolidated(market_).positions(account_).margin;
    }

    /// @inheritdoc ISynthetixHandler
    function leverageDeviationFactor(
        address market_,
        address account_,
        uint256 targetLeverage_
    ) public view returns (uint256) {
        uint256 initialNotional = initialMargin(market_, account_).mul(
            targetLeverage_
        );
        if (initialNotional == 0) return 0;
        uint256 currentNotional = notionalValue(market_, account_);
        return currentNotional.absSub(initialNotional).div(initialNotional);
    }

    /// @inheritdoc ISynthetixHandler
    function leverage(
        address market_,
        address account_
    ) public view override returns (uint256) {
        uint256 notionalValue_ = notionalValue(market_, account_);
        uint256 marginRemaining_ = remainingMargin(market_, account_);
        if (marginRemaining_ == 0) revert NoMargin();
        return notionalValue_.div(marginRemaining_);
    }

    /// @inheritdoc ISynthetixHandler
    function notionalValue(
        address market_,
        address account_
    ) public view override returns (uint256) {
        (int256 notionalValue_, bool invalid_) = IPerpsV2MarketConsolidated(
            market_
        ).notionalValue(account_);
        if (invalid_) return 0;
        if (notionalValue_ < 0) return uint256(-notionalValue_);
        return uint256(notionalValue_);
    }

    /// @inheritdoc ISynthetixHandler
    function isLong(
        address market_,
        address account_
    ) public view override returns (bool) {
        (int256 notionalValue_, bool invalid_) = IPerpsV2MarketConsolidated(
            market_
        ).notionalValue(account_);
        if (invalid_) revert ErrorGettingIsLong();
        if (notionalValue_ == 0) revert ErrorGettingIsLong();
        return notionalValue_ > 0;
    }

    /// @inheritdoc ISynthetixHandler
    function remainingMargin(
        address market_,
        address account_
    ) public view override returns (uint256) {
        (uint256 marginRemaining_, bool invalid_) = IPerpsV2MarketConsolidated(
            market_
        ).remainingMargin(account_);
        if (invalid_) return 0;
        return marginRemaining_;
    }

    /// @inheritdoc ISynthetixHandler
    function fillPrice(
        address market_,
        int256 sizeDelta_
    ) public view override returns (uint256) {
        (uint256 fillPrice_, bool invalid_) = IPerpsV2MarketConsolidated(
            market_
        ).fillPrice(sizeDelta_);
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
        address market_
    ) public view override returns (uint256) {
        (uint256 assetPrice_, bool invalid_) = IPerpsV2MarketConsolidated(
            market_
        ).assetPrice();
        if (invalid_) revert ErrorGettingAssetPrice();
        return assetPrice_;
    }

    function _pnl(
        address market_,
        address account_
    ) internal view returns (int256) {
        (int256 pnl_, bool invalid_) = IPerpsV2MarketConsolidated(market_)
            .profitLoss(account_);
        if (invalid_) revert ErrorGettingPnl();
        return pnl_;
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
