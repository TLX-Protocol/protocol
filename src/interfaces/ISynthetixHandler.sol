// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ISynthetixHandler {
    error ErrorGettingPnl();
    error ErrorGettingOrderFee();
    error ErrorGettingIsLong();
    error ErrorGettingFillPrice();
    error ErrorGettingAssetPrice();
    error NoMargin();

    /**
     * @notice Deposit `amount` of margin to Synthetix for the `market`.
     * @dev Should be called with delegatecall.
     * @param market The market to deposit margin for.
     * @param amount The amount of margin to deposit.
     */
    function depositMargin(address market, uint256 amount) external;

    /**
     * @notice Withdraw `amount` of margin from Synthetix for the `market`.
     * @dev Should be called with delegatecall.
     * @param market The market to withdraw margin for.
     * @param amount The amount of margin to withdraw.
     */
    function withdrawMargin(address market, uint256 amount) external;

    /**
     * @notice Submit a leverage update for the `market`.
     * @dev Should be called with delegatecall.
     * @param market The market to submit a leverage update for.
     * @param leverage The new leverage to target.
     * @param isLong Whether the position is long or short.
     */
    function submitLeverageUpdate(
        address market,
        uint256 leverage,
        bool isLong
    ) external;

    /**
     * @notice Returns the address for the market of the `targetAsset`.
     * @param targetAsset The asset to return the market for.
     * @return market The address for the market of the `targetAsset`.
     */
    function market(
        string calldata targetAsset
    ) external view returns (address market);

    /**
     * @notice Returns if the `account` has a pending leverage update.
     * @param market The market to check if the `account` has a pending leverage update for.
     * @param account The account to check if they have a pending leverage update.
     * @return hasPendingLeverageUpdate Whether the `account` has a pending leverage update.
     */
    function hasPendingLeverageUpdate(
        address market,
        address account
    ) external view returns (bool hasPendingLeverageUpdate);

    /**
     * @notice Returns if the `account` has an open position for the `market`.
     * @param market The market to check if the `account` has an open position for.
     * @param account The account to check if they have an open position for the `market`.
     * @return hasOpenPosition Whether the `acccount` has an open position for the `market`.
     */
    function hasOpenPosition(
        address market,
        address account
    ) external view returns (bool hasOpenPosition);

    /**
     * @notice Returns the total value of the `account`'s position for the `market` in the Base Asset.
     * @param market The market to get the total value of the `account`'s position for.
     * @param account The account to get the total value of the `account`'s position for the `market`.
     * @return totalValue The total value of the `account`'s position for the `market` in the Base Asset.
     */
    function totalValue(
        address market,
        address account
    ) external view returns (uint256 totalValue);

    /**
     * @notice Returns the deviation factor from our target leverage.
     * @dev Used for rebalances, if |1 - leverageDeviationFactor| exceeds our `rebalanceThreshold` then a rebalance is triggered.
     * When this factoris below 1, it means we are underleveraged, when it is above 1, it means we are overleveraged.
     * @param market The market to get the leverage of the `account`'s position for.
     * @param account The account to get the leverage of the `account`'s position for the `market`.
     * @return leverageDeviationFactor The deviation factor from our target leverage.
     */
    function leverageDeviationFactor(
        address market,
        address account,
        uint256 targetLeverage
    ) external view returns (uint256 leverageDeviationFactor);

    /**
     * @notice Returns the leverage of the `account`'s position for the `market`.
     * @param market The market to get the leverage of the `account`'s position for.
     * @param account The account to get the leverage of the `account`'s position for the `market`.
     * @return leverage The leverage of the `account`'s position for the `market`.
     */
    function leverage(
        address market,
        address account
    ) external view returns (uint256 leverage);

    /**
     * @notice Returns the notional value of the `account`'s position for the `market` in the Base Asset.
     * @param market The market to get the notional value of the `account`'s position for.
     * @param account The account to get the notional value of the `account`'s position for the `market`.
     * @return notionalValue The notional value of the `account`'s position for the `market` in the Base Asset.
     */
    function notionalValue(
        address market,
        address account
    ) external view returns (uint256);

    /**
     * @notice Returns if the `account`'s position for the `m` is long.
     * @dev Reverts if the `account` does not have an open position for the `targetAsset`.
     * @param market The market to check if the `account`'s position for is long.
     * @param account The account to check if the `account`'s position for the `targetAsset` is long.
     * @return isLong Whether the `account`'s position for the `market` is long.
     */
    function isLong(
        address market,
        address account
    ) external view returns (bool isLong);

    /**
     * @notice Returns the initial margin of the `account`'s position for the `market`.
     * This does not take into account any profit or loss
     * @param market The market to get the remaining margin of the `account`'s position for.
     * @param account The account to get the remaining margin of the `account`'s position for the `market`.
     * @return initialMargin The initial margin of the `account`'s position for the `market`.
     */
    function initialMargin(
        address market,
        address account
    ) external view returns (uint256 initialMargin);

    /**
     * @notice Returns the remaining margin of the `account`'s position for the `market`.
     * @param market The market to get the remaining margin of the `account`'s position for.
     * @param account The account to get the remaining margin of the `account`'s position for the `market`.
     * @return remainingMargin The remaining margin of the `account`'s position for the `market`.
     */
    function remainingMargin(
        address market,
        address account
    ) external view returns (uint256 remainingMargin);

    /**
     * @notice Returns the fill price of the `market` for a trade of `sizeDelta` tokens.
     * @param market The market to get the fill price of.
     * @param sizeDelta The amount of tokens to get the fill price for.
     * @return fillPrice The fill price of the `market` for a trade of `sizeDelta` tokens.
     */
    function fillPrice(
        address market,
        int256 sizeDelta
    ) external view returns (uint256 fillPrice);

    /**
     * @notice Returns the price of the `market`.
     * @param market The market to return the price for.
     * @return assetPrice The price of the `market`.
     */
    function assetPrice(
        address market
    ) external view returns (uint256 assetPrice);

    /**
     * @notice Returns if the `targetAsset` is supported.
     * @param targetAsset The asset to check if it is supported.
     * @return isSupported Whether the `targetAsset` is supported.
     */
    function isAssetSupported(
        string calldata targetAsset
    ) external view returns (bool isSupported);

    /**
     * @notice Returns the Maximum Market value for the `targetAsset`.
     * @param targetAsset The asset to get the Maximum Market value for.
     * @return maxMarketValue The Maximum Market value for the `targetAsset`.
     */
    function maxMarketValue(
        string calldata targetAsset
    ) external view returns (uint256 maxMarketValue);
}
