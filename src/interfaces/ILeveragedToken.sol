// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ILeveragedToken is IERC20Metadata {
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
    event Rebalanced(uint256 currentLeverage);
    event PausedSet(bool isPaused);

    error InsufficientAmount();
    error CannotRebalance();
    error LeverageUpdatePending();
    error Paused();
    error ExceedsLimit();
    error Inactive();

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
     * @notice Charges the streaming fee.
     * @dev This is done automatically during rebalances, but we might want to do this more frequently.
     */
    function chargeStreamingFee() external;

    /**
     * @notice Sets if the leveraged token is paused.
     * @dev Only callable by the contract owner.
     * @param isPaused If the leveraged token should be paused or not.
     */
    function setIsPaused(bool isPaused) external;

    /**
     * @notice Returns the target asset of the leveraged token.
     * @return targetAsset The target asset of the leveraged token.
     */
    function targetAsset() external view returns (string memory targetAsset);

    /**
     * @notice Returns the target leverage of the leveraged token.
     * @return targetLeverage The target leverage of the leveraged token.
     */
    function targetLeverage() external view returns (uint256 targetLeverage);

    /**
     * @notice Returns if the leveraged token is long or short.
     * @return isLong `true` if the leveraged token is long and `false` if the leveraged token is short.
     */
    function isLong() external view returns (bool isLong);

    /**
     * @notice Returns if the leveraged token is active,
     * @dev A token is active if it still has some positive exchange rate (i.e. has not been liquidated).
     * @return isActive If the leveraged token is active.
     */
    function isActive() external view returns (bool isActive);

    /**
     * @notice Returns if the leveraged token is paused,
     * @dev If a token is paused, deposits are disabled.
     * @return isPaused If the leveraged token is paused.
     */
    function isPaused() external view returns (bool isPaused);

    /**
     * @notice Returns the rebalance threshold.
     * @dev Represented as a percent in 18 decimals, e.g. 20% = 0.2e18.
     * @return rebalanceThreshold The rebalance threshold.
     */
    function rebalanceThreshold()
        external
        view
        returns (uint256 rebalanceThreshold);

    /**
     * @notice Returns the exchange rate from one leveraged token to one base asset.
     * @dev In 18 decimals.
     * @return exchangeRate The exchange rate.
     */
    function exchangeRate() external view returns (uint256 exchangeRate);

    /**
     * @notice Returns the expected slippage from making an adjustment to a position.
     * @param baseAmount Margin amount to deposit in units of base asset.
     * @param isDeposit If the adjustment is a deposit.
     * @return slippage Slippage in units of base asset.
     * @return isLoss Whether the slippage is a loss.
     */
    function computePriceImpact(
        uint256 baseAmount,
        bool isDeposit
    ) external view returns (uint256 slippage, bool isLoss);

    /**
     * @notice Returns if the leveraged token can be rebalanced.
     * @return canRebalance If the leveraged token can be rebalanced.
     */
    function canRebalance() external view returns (bool canRebalance);
}
