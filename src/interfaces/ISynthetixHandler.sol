// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ISynthetixHandler {
    /**
     * @notice Deposit `amount` of margin to Synthetix for the `targetAsset`.
     * @dev Should be called with delegatecall.
     * @param targetAsset The asset to deposit margin for.
     * @param amount The amount of margin to deposit.
     */
    function depositMargin(
        string calldata targetAsset,
        uint256 amount
    ) external;

    /**
     * @notice Withdraw `amount` of margin from Synthetix for the `targetAsset`.
     * @dev Should be called with delegatecall.
     * @param targetAsset The asset to withdraw margin for.
     * @param amount The amount of margin to withdraw.
     */
    function withdrawMargin(
        string calldata targetAsset,
        uint256 amount
    ) external;

    /**
     * @notice Submit a leverage update for the `targetAsset`.
     * @dev Should be called with delegatecall.
     * @param targetAsset The asset to submit a leverage update for.
     * @param leverage The new leverage to target.
     * @param isLong Whether the position is long or short.
     */
    function submitLeverageUpdate(
        string calldata targetAsset,
        uint256 leverage,
        bool isLong
    ) external;

    /**
     * @notice Returns if the caller has an open position for the `targetAsset`.
     * @param targetAsset The asset to check if the caller has an open position for.
     * @return hasOpenPosition Whether the caller has an open position for the `targetAsset`.
     */
    function hasOpenPosition(
        string calldata targetAsset
    ) external view returns (bool hasOpenPosition);

    /**
     * @notice Returns if the `account` has an open position for the `targetAsset`.
     * @param targetAsset The asset to check if the `account` has an open position for.
     * @param account The account to check if they have an open position for the `targetAsset`.
     * @return hasOpenPosition Whether the `acccount` has an open position for the `targetAsset`.
     */
    function hasOpenPosition(
        string calldata targetAsset,
        address account
    ) external view returns (bool hasOpenPosition);

    /**
     * @notice Returns the total value of the callers position for the `targetAsset` in the Base Asset.
     * @param targetAsset The asset to get the total value of the callers position for.
     * @return totalValue The total value of the callers position for the `targetAsset` in the Base Asset.
     */
    function totalValue(
        string calldata targetAsset
    ) external view returns (uint256 totalValue);

    /**
     * @notice Returns the total value of the `account`'s position for the `targetAsset` in the Base Asset.
     * @param targetAsset The asset to get the total value of the `account`'s position for.
     * @param account The account to get the total value of the `account`'s position for the `targetAsset`.
     * @return totalValue The total value of the `account`'s position for the `targetAsset` in the Base Asset.
     */
    function totalValue(
        string calldata targetAsset,
        address account
    ) external view returns (uint256 totalValue);

    /**
     * @notice Returns the leverage of the callers position for the `targetAsset`.
     * @param targetAsset The asset to get the leverage of the callers position for.
     * @return leverage The leverage of the callers position for the `targetAsset`.
     */
    function leverage(
        string calldata targetAsset
    ) external view returns (uint256 leverage);

    /**
     * @notice Returns the leverage of the `account`'s position for the `targetAsset`.
     * @param targetAsset The asset to get the leverage of the `account`'s position for.
     * @param account The account to get the leverage of the `account`'s position for the `targetAsset`.
     * @return leverage The leverage of the `account`'s position for the `targetAsset`.
     */
    function leverage(
        string calldata targetAsset,
        address account
    ) external view returns (uint256 leverage);

    /**
     * @notice Returns the notional value of the callers position for the `targetAsset` in the Base Asset.
     * @param targetAsset The asset to get the notional value of the callers position for.
     * @return notionalValue The notional value of the callers position for the `targetAsset` in the Base Asset.
     */
    function notionalValue(
        string calldata targetAsset
    ) external view returns (uint256);

    /**
     * @notice Returns the notional value of the `account`'s position for the `targetAsset` in the Base Asset.
     * @param targetAsset The asset to get the notional value of the `account`'s position for.
     * @param account The account to get the notional value of the `account`'s position for the `targetAsset`.
     * @return notionalValue The notional value of the `account`'s position for the `targetAsset` in the Base Asset.
     */
    function notionalValue(
        string calldata targetAsset,
        address account
    ) external view returns (uint256);

    /**
     * @notice Returns if the callers position for the `targetAsset` is long.
     * @dev Reverts if the caller does not have an open position for the `targetAsset`.
     * @param targetAsset The asset to check if the callers position for is long.
     * @return isLong Whether the callers position for the `targetAsset` is long.
     */
    function isLong(
        string calldata targetAsset
    ) external view returns (bool isLong);

    /**
     * @notice Returns if the `account`'s position for the `targetAsset` is long.
     * @dev Reverts if the `account` does not have an open position for the `targetAsset`.
     * @param targetAsset The asset to check if the `account`'s position for is long.
     * @param account The account to check if the `account`'s position for the `targetAsset` is long.
     * @return isLong Whether the `account`'s position for the `targetAsset` is long.
     */
    function isLong(
        string calldata targetAsset,
        address account
    ) external view returns (bool isLong);

    /**
     * @notice Returns the remaining margin of the callers position for the `targetAsset`.
     * @param targetAsset The asset to get the remaining margin of the callers position for.
     * @return remainingMargin The remaining margin of the callers position for the `targetAsset`.
     */
    function remainingMargin(
        string calldata targetAsset
    ) external view returns (uint256 remainingMargin);

    /**
     * @notice Returns the remaining margin of the `account`'s position for the `targetAsset`.
     * @param targetAsset The asset to get the remaining margin of the `account`'s position for.
     * @param account The account to get the remaining margin of the `account`'s position for the `targetAsset`.
     * @return remainingMargin The remaining margin of the `account`'s position for the `targetAsset`.
     */
    function remainingMargin(
        string calldata targetAsset,
        address account
    ) external view returns (uint256 remainingMargin);

    /**
     * @notice Returns the fill price of the `targetAsset` for a trade of `sizeDelta` tokens.
     * @param targetAsset The asset to get the fill price of.
     * @param sizeDelta The amount of tokens to get the fill price for.
     * @return fillPrice The fill price of the `targetAsset` for a trade of `sizeDelta` tokens.
     */
    function fillPrice(
        string calldata targetAsset,
        int256 sizeDelta
    ) external view returns (uint256 fillPrice);

    /**
     * @notice Returns the price of the `targetAsset`.
     * @param targetAsset The asset to get the price of.
     * @return assetPrice The price of the `targetAsset`.
     */
    function assetPrice(
        string calldata targetAsset
    ) external view returns (uint256 assetPrice);

    /**
     * @notice Returns if the `targetAsset` is supported.
     * @param targetAsset The asset to check if it is supported.
     * @return isSupported Whether the `targetAsset` is supported.
     */
    function isAssetSupported(
        string calldata targetAsset
    ) external view returns (bool isSupported);
}
