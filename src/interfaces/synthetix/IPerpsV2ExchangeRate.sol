// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

// https://docs.synthetix.io/contracts/source/contracts/IPerpsV2ExchangeRate
interface IPerpsV2ExchangeRate {
    function setOffchainPriceFeedId(
        bytes32 assetId,
        bytes32 priceFeedId
    ) external;

    /* ========== VIEWS ========== */

    function offchainPriceFeedId(
        bytes32 assetId
    ) external view returns (bytes32);

    /* ---------- priceFeeds mutation ---------- */

    function updatePythPrice(
        address sender,
        bytes[] calldata priceUpdateData
    ) external payable;

    // it is a view but it can revert
    function resolveAndGetPrice(
        bytes32 assetId,
        uint maxAge
    ) external view returns (uint price, uint publishTime);

    // it is a view but it can revert
    function resolveAndGetLatestPrice(
        bytes32 assetId
    ) external view returns (uint price, uint publishTime);
}
