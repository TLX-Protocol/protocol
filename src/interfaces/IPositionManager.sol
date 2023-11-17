// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ILeveragedToken} from "./ILeveragedToken.sol";

interface IPositionManager {
    event Minted(
        address indexed account,
        uint256 leveragedTokenAmount,
        uint256 baseAssetAmount
    );
    event Redeemed(
        address indexed account,
        uint256 leveragedTokenAmount,
        uint256 baseAssetAmount
    );

    error InsufficientAmount();
    error CannotRebalance();
    error LeverageUpdatePending();

    /**
     * @notice Mints some leveraged tokens to the caller with the given baseAmountIn of the base asset.
     * @param baseAmountIn The amount of the base asset to mint with.
     * @param minLeveragedTokenAmountOut The minimum amount of leveragedTokens to mint (reverts otherwise).
     * @return leveragedTokenAmountOut The amount of leveragedTokens minted.
     */
    function mint(
        uint256 baseAmountIn,
        uint256 minLeveragedTokenAmountOut
    ) external returns (uint256 leveragedTokenAmountOut);

    /**
     * @notice Redeems leveragedTokenAmount of the leveraged token and returns the base asset.
     * @param leveragedTokenAmount The amount of the leveraged token to redeem.
     * @param minBaseAmountReceived The minimum amount of the base asset to receive (reverts otherwise).
     * @return baseAmountReceived The amount of the base asset received.
     */
    function redeem(
        uint256 leveragedTokenAmount,
        uint256 minBaseAmountReceived
    ) external returns (uint256 baseAmountReceived);

    /**
     * @notice Rebalances the position to the target leverage.
     */
    function rebalance() external;

    /**
     * @notice Sets the leveraged token of the position.
     * @dev Can only be called once, set as part of deployment.
     * @param leveragedToken The leveraged token to set.
     */
    function setLeveragedToken(address leveragedToken) external;

    /**
     * @notice Returns the leveraged token of the position.
     * @return leveragedToken The leveraged token of the position.
     */
    function leveragedToken()
        external
        view
        returns (ILeveragedToken leveragedToken);

    /**
     * @notice Returns the exchange rate from one leveraged token to one base asset.
     * @dev In 18 decimals.
     * @return exchangeRate The exchange rate.
     */
    function exchangeRate() external view returns (uint256 exchangeRate);

    /**
     * @notice Returns if the leveraged token can be rebalanced.
     * @return canRebalance If the leveraged token can be rebalanced.
     */
    function canRebalance() external view returns (bool canRebalance);
}
