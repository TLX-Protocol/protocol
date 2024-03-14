// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ISynthetixHandler} from "./interfaces/ISynthetixHandler.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IPerpsV2MarketSettings} from "./interfaces/synthetix/IPerpsV2MarketSettings.sol";
import {IPerpsV2MarketData} from "./interfaces/synthetix/IPerpsV2MarketData.sol";
import {IPerpsV2MarketConsolidated} from "./interfaces/synthetix/IPerpsV2MarketConsolidated.sol";
import {IPerpsV2MarketBaseTypes} from "./interfaces/synthetix/IPerpsV2MarketBaseTypes.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

contract SynthetixHandler is ISynthetixHandler {
    using ScaledNumber for uint256;
    using ScaledNumber for int256;

    IPerpsV2MarketData internal immutable _perpsV2MarketData;
    IPerpsV2MarketSettings internal immutable _marketSettings;
    IAddressProvider internal immutable _addressProvider;

    uint256 internal constant _SLIPPAGE_TOLERANCE = 0.02e18; // 2%

    constructor(
        address addressProvider_,
        address perpsV2MarketData_,
        address marketSettings_
    ) {
        _perpsV2MarketData = IPerpsV2MarketData(perpsV2MarketData_);
        _addressProvider = IAddressProvider(addressProvider_);
        _marketSettings = IPerpsV2MarketSettings(marketSettings_);
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
    function depositMargin(address market_, uint256 amount_) public override {
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

    function computePriceImpact(
        address market_,
        uint256 leverage_,
        uint256 baseAmount_,
        bool isLong_,
        bool isDeposit_
    ) public view override returns (uint256, bool) {
        uint256 assetPrice_ = assetPrice(market_);
        uint256 absTargetSizeDelta_ = baseAmount_.mul(leverage_).div(
            assetPrice_
        );
        int256 targetSizeDelta_ = int256(absTargetSizeDelta_);
        if (!isLong_) targetSizeDelta_ = -targetSizeDelta_; // Invert if shorting
        if (!isDeposit_) targetSizeDelta_ = -targetSizeDelta_; // Invert if redeeming
        uint256 fillPrice_ = fillPrice(market_, targetSizeDelta_);

        bool isLoss = (isLong_ && fillPrice_ > assetPrice_) ||
            (!isLong_ && fillPrice_ < assetPrice_);
        uint256 slippage = absTargetSizeDelta_.mul(
            assetPrice_.absSub(fillPrice_)
        );
        return (slippage, isLoss);
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
        return
            IPerpsV2MarketConsolidated(market_).positions(account_).size != 0;
    }

    /// @inheritdoc ISynthetixHandler
    function totalValue(
        address market_,
        address account_
    ) public view override returns (uint256) {
        return remainingMargin(market_, account_);
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
        return
            currentNotional.absSub(initialNotional).div(initialNotional).mul(
                targetLeverage_
            );
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

    /// @inheritdoc ISynthetixHandler
    function maxMarketValue(
        string calldata targetAsset_,
        address market_
    ) public view override returns (uint256) {
        uint256 price_ = assetPrice(market_);
        return _marketSettings.maxMarketValue(_key(targetAsset_)).mul(price_);
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
        return _marketSettings.minKeeperFee();
    }

    function _key(
        string calldata targetAsset_
    ) internal pure returns (bytes32) {
        return bytes32(bytes(abi.encodePacked("s", targetAsset_, "PERP")));
    }
}
