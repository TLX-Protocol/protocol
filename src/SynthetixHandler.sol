// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IPerpsV2MarketData} from "./interfaces/synthetix/IPerpsV2MarketData.sol";
import {IPerpsV2MarketConsolidated} from "./interfaces/synthetix/IPerpsV2MarketConsolidated.sol";

contract SynthetixHandler {
    error NoMarket();

    IPerpsV2MarketData internal immutable _perpsV2MarketData;
    IAddressProvider internal immutable _addressProvider;

    constructor(address addressProvider_, address perpsV2MarketData_) {
        _perpsV2MarketData = IPerpsV2MarketData(perpsV2MarketData_);
        _addressProvider = IAddressProvider(addressProvider_);
    }

    function depositMargin(
        string calldata targetAsset,
        uint256 amount
    ) external {
        IPerpsV2MarketConsolidated market_ = _market(targetAsset);
        _addressProvider.baseAsset().approve(address(market_), amount);
        market_.transferMargin(int256(amount));
    }

    function withdrawMargin(
        string calldata targetAsset,
        uint256 amount
    ) external {
        IPerpsV2MarketConsolidated market_ = _market(targetAsset);
        market_.transferMargin(-int256(amount));
    }

    function modifyPosition(
        string calldata targetAsset,
        uint256 desiredFillPrice,
        uint256 sizeDelta,
        bool isLong
    ) external {
        IPerpsV2MarketConsolidated market_ = _market(targetAsset);
        if (address(market_) == address(0)) revert NoMarket();
    }

    function _market(
        string calldata targetAsset
    ) internal view returns (IPerpsV2MarketConsolidated) {
        IPerpsV2MarketData.MarketData memory marketData = _perpsV2MarketData
            .marketDetailsForKey(_key(targetAsset));
        if (marketData.market == address(0)) revert NoMarket();
        return IPerpsV2MarketConsolidated(marketData.market);
    }

    function _key(string calldata targetAsset) internal pure returns (bytes32) {
        return bytes32(bytes(abi.encodePacked("s", targetAsset, "PERP")));
    }
}
