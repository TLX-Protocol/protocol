// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IPerpsV2MarketData {
    struct FeeRates {
        uint takerFee;
        uint makerFee;
        uint takerFeeDelayedOrder;
        uint makerFeeDelayedOrder;
        uint takerFeeOffchainDelayedOrder;
        uint makerFeeOffchainDelayedOrder;
    }

    struct MarketLimits {
        uint maxLeverage;
        uint maxMarketValue;
    }

    struct FundingParameters {
        uint maxFundingVelocity;
        uint skewScale;
    }

    struct Sides {
        uint long;
        uint short;
    }

    struct MarketSizeDetails {
        uint marketSize;
        Sides sides;
        uint marketDebt;
        int marketSkew;
    }

    struct PriceDetails {
        uint price;
        bool invalid;
    }

    struct MarketData {
        address market;
        bytes32 baseAsset;
        bytes32 marketKey;
        FeeRates feeRates;
        MarketLimits limits;
        FundingParameters fundingParameters;
        MarketSizeDetails marketSizeDetails;
        PriceDetails priceDetails;
    }

    function marketDetailsForKey(
        bytes32 marketKey
    ) external view returns (MarketData memory);
}
