// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IPositionManager {
    event Minted(
        address indexed leveragedToken,
        address indexed account,
        uint256 leveragedTokenAmount,
        uint256 baseAssetAmount
    );
    event Redeemed(
        address indexed leveragedToken,
        address indexed account,
        uint256 leveragedTokenAmount,
        uint256 baseAssetAmount
    );

    error NotLeveragedToken();
    error NotPositionManager();
    error InsufficientAmount();

    /**
     * @notice Mints some leveraged tokens to the caller with the given baseAmountIn of the base asset.
     * @param leveragedToken The address of the leveraged token to mint.
     * @param baseAmountIn The amount of the base asset to mint with.
     * @param minLeveragedTokenAmountOut The minimum amount of leveragedTokens to mint (reverts otherwise).
     * @return leveragedTokenAmountOut The amount of leveragedTokens minted.
     */
    function mintAmountIn(
        address leveragedToken,
        uint256 baseAmountIn,
        uint256 minLeveragedTokenAmountOut
    ) external returns (uint256 leveragedTokenAmountOut);

    /**
     * @notice Mints leveragedTokenAmountOut leveraged tokens to the caller.
     * @param leveragedToken The address of the leveraged token to mint.
     * @param leveragedTokenAmountOut The amount of the leveraged tokens to mint.
     * @param maxBaseAmountIn The maximum amount of the base asset to use (reverts otherwise).
     * @return baseAmountIn The amount of the base asset used.
     */
    function mintAmountOut(
        address leveragedToken,
        uint256 leveragedTokenAmountOut,
        uint256 maxBaseAmountIn
    ) external returns (uint256 baseAmountIn);

    /**
     * @notice Redeems leveragedTokenAmount of the leveraged token and returns the base asset.
     * @param leveragedToken The address of the leveraged token to redeem.
     * @param leveragedTokenAmount The amount of the leveraged token to redeem.
     * @param minBaseAmountReceived The minimum amount of the base asset to receive (reverts otherwise).
     * @return baseAmountReceived The amount of the base asset received.
     */
    function redeem(
        address leveragedToken,
        uint256 leveragedTokenAmount,
        uint256 minBaseAmountReceived
    ) external returns (uint256 baseAmountReceived);

    /**
     * @notice Rebalances the position to the target leverage.
     */
    function rebalance() external returns (uint256);

    /**
     * @notice Returns the target asset of the position.
     * @return targetAsset The target asset of the position.
     */
    function targetAsset() external view returns (string memory targetAsset);

    /**
     * @notice Returns the exchange rate from one leveraged token to one base asset.
     * @dev In 18 decimals.
     * @param leveragedToken The address of the leveraged token.
     * @return exchangeRate The exchange rate.
     */
    function exchangeRate(
        address leveragedToken
    ) external view returns (uint256 exchangeRate);
}
