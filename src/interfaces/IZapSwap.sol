// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IZapSwap {
    event Minted(
        address indexed account,
        address indexed leveragedToken,
        address assetIn,
        uint256 amountIn,
        uint256 leveragedTokenAmountOut
    );
    event Redeemed(
        address indexed account,
        address indexed leveragedToken,
        uint256 leveragedTokenAmountIn,
        address assetOut,
        uint256 amountOut
    );

    error InvalidAddress();
    error InsufficientAmount();

    /**
     * @notice Returns the asset being swapped for the baseAsset.
     * @return asset The asset being swapped for the baseAsset.
     */
    function zapAsset() external returns (address asset);

    /**
     * @notice Mints the target leveraged tokens to the caller with the given amountIn of the specific stablecoin.
     * @param leveragedTokenAddress Address of target leveraged token to mint
     * @param amountIn The amount of the stablecoin to mint with.
     * @param minLeveragedTokenAmountOut The minimum amount of leveragedTokens to mint (reverts otherwise).
     * @return leveragedTokenAmountOut The amount of leveragedTokens minted.
     */
    function mint(
        address leveragedTokenAddress,
        uint256 amountIn,
        uint256 minLeveragedTokenAmountOut
    ) external returns (uint256 leveragedTokenAmountOut);

    /**
     * @notice Redeems the target leveraged tokens and swaps the baseAsset for the specific stablecoin.
     * @param leveragedTokenAddress Address of target leveraged token to redeem
     * @param leveragedTokenAmountIn The amount of the leveraged tokens to redeem.
     * @param minZapAssetAmountOut The minimum amount of the zapAsset to receive (reverts otherwise).
     * @return amountOut The amount of stablecoin received.
     */
    function redeem(
        address leveragedTokenAddress,
        uint256 leveragedTokenAmountIn,
        uint256 minZapAssetAmountOut
    ) external returns (uint256 amountOut);
}
