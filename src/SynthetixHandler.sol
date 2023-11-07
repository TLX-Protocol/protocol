// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IPerpsV2MarketData} from "./interfaces/synthetix/IPerpsV2MarketData.sol";
import {IPerpsV2MarketConsolidated} from "./interfaces/synthetix/IPerpsV2MarketConsolidated.sol";
import {IPerpsV2MarketBaseTypes} from "./interfaces/synthetix/IPerpsV2MarketBaseTypes.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

contract SynthetixHandler {
    using ScaledNumber for uint256;

    error NoMarket();
    error ErrorGettingPnl();
    error ErrorGettingOrderFee();
    error ErrorGettingIsLong();
    error NoMargin();

    IPerpsV2MarketData internal immutable _perpsV2MarketData;
    IAddressProvider internal immutable _addressProvider;

    constructor(address addressProvider_, address perpsV2MarketData_) {
        _perpsV2MarketData = IPerpsV2MarketData(perpsV2MarketData_);
        _addressProvider = IAddressProvider(addressProvider_);
    }

    function depositMargin(
        string calldata targetAsset_,
        uint256 amount_
    ) external {
        IPerpsV2MarketConsolidated market_ = _market(targetAsset_);
        _addressProvider.baseAsset().approve(address(market_), amount_);
        market_.transferMargin(int256(amount_));
    }

    function withdrawMargin(
        string calldata targetAsset_,
        uint256 amount_
    ) external {
        _market(targetAsset_).transferMargin(-int256(amount_));
    }

    // TODO Test
    function submitLeverageUpdate(
        string calldata targetAsset_,
        uint256 leverage_,
        bool isLong_,
        uint256 desiredFillPrice_
    ) external {
        uint256 marginAmount_ = remainingMargin(targetAsset_, address(this));
        if (marginAmount_ == 0) revert NoMargin();
        uint256 notionalValue_ = notionalValue(targetAsset_, address(this));
        uint256 targetNotional_ = marginAmount_.mul(leverage_);
        int256 sizeDelta_ = int256(targetNotional_) - int256(notionalValue_);
        if (!isLong_) sizeDelta_ = -sizeDelta_;
        IPerpsV2MarketConsolidated market_ = _market(targetAsset_);
        market_.submitOffchainDelayedOrder(sizeDelta_, desiredFillPrice_);
    }

    function hasOpenPosition(
        string calldata targetAsset_
    ) external view returns (bool) {
        return hasOpenPosition(targetAsset_, msg.sender);
    }

    function hasOpenPosition(
        string calldata targetAsset_,
        address account_
    ) public view returns (bool) {
        return notionalValue(targetAsset_, account_) != 0;
    }

    function totalValue(
        string calldata targetAsset_
    ) external view returns (uint256) {
        return totalValue(targetAsset_, msg.sender);
    }

    function totalValue(
        string calldata targetAsset_,
        address account_
    ) public view returns (uint256) {
        uint256 remainingMargin_ = remainingMargin(targetAsset_, account_);
        uint256 notionalValue_ = notionalValue(targetAsset_, account_);
        int256 pnl_ = _pnl(targetAsset_, account_);
        uint256 closeFee_ = _orderFee(targetAsset_, -int256(notionalValue_));
        return uint256(int256(remainingMargin_ - closeFee_) + pnl_);
    }

    function leverage(
        string calldata targetAsset_
    ) external view returns (uint256) {
        return leverage(targetAsset_, msg.sender);
    }

    function leverage(
        string calldata targetAsset_,
        address account_
    ) public view returns (uint256) {
        uint256 notionalValue_ = notionalValue(targetAsset_, account_);
        uint256 marginRemaining_ = remainingMargin(targetAsset_, account_);
        if (marginRemaining_ == 0) revert NoMargin();
        return notionalValue_.div(marginRemaining_);
    }

    function notionalValue(
        string calldata targetAsset_
    ) external view returns (uint256) {
        return notionalValue(targetAsset_, msg.sender);
    }

    function notionalValue(
        string calldata targetAsset_,
        address account_
    ) public view returns (uint256) {
        (int256 notionalValue_, bool invalid_) = _market(targetAsset_)
            .notionalValue(account_);
        if (invalid_) return 0;
        if (notionalValue_ < 0) return uint256(-notionalValue_);
        return uint256(notionalValue_);
    }

    function isLong(string calldata targetAsset_) external view returns (bool) {
        return isLong(targetAsset_, msg.sender);
    }

    function isLong(
        string calldata targetAsset_,
        address account_
    ) public view returns (bool) {
        (int256 notionalValue_, bool invalid_) = _market(targetAsset_)
            .notionalValue(account_);
        if (invalid_) revert ErrorGettingIsLong();
        if (notionalValue_ == 0) revert ErrorGettingIsLong();
        return notionalValue_ > 0;
    }

    // TODO Test
    function remainingMargin(
        string calldata targetAsset_
    ) external view returns (uint256) {
        return remainingMargin(targetAsset_, msg.sender);
    }

    function remainingMargin(
        string calldata targetAsset_,
        address account_
    ) public view returns (uint256) {
        (uint256 marginRemaining_, bool invalid_) = _market(targetAsset_)
            .remainingMargin(account_);
        if (invalid_) return 0;
        return marginRemaining_;
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

    function _orderFee(
        string calldata targetAsset_,
        int256 sizeDelta_
    ) internal view returns (uint256) {
        (uint256 fee_, bool invalid_) = _market(targetAsset_).orderFee(
            sizeDelta_,
            IPerpsV2MarketBaseTypes.OrderType.Delayed
        );
        if (invalid_) revert ErrorGettingOrderFee();
        return fee_;
    }

    function _market(
        string calldata targetAsset_
    ) internal view returns (IPerpsV2MarketConsolidated) {
        IPerpsV2MarketData.MarketData memory marketData_ = _perpsV2MarketData
            .marketDetailsForKey(_key(targetAsset_));
        if (marketData_.market == address(0)) revert NoMarket();
        return IPerpsV2MarketConsolidated(marketData_.market);
    }

    function _key(
        string calldata targetAsset_
    ) internal pure returns (bytes32) {
        return bytes32(bytes(abi.encodePacked("s", targetAsset_, "PERP")));
    }
}
