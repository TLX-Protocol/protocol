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

    /**
     * @notice Returns the asset supported by the zap.
     * @return asset The asset supported by the zap.
     */
    function zapAsset() external returns (address asset);

    /**
     * @notice Swaps the zap asset for the base asset and mints the target leveraged tokens for the caller.
     * @param leveragedTokenAddress Address of target leveraged token to mint.
     * @param zapAssetAmountIn The amount of the zap asset to mint with.
     * @param minLeveragedTokenAmountOut The minimum amount of leveraged tokens to receive (reverts otherwise).
     * @return leveragedTokenAmountOut The amount of leveraged tokens minted.
     */
    function mint(
        address leveragedTokenAddress,
        uint256 zapAssetAmountIn,
        uint256 minLeveragedTokenAmountOut
    ) external returns (uint256 leveragedTokenAmountOut);

    /**
     * @notice Redeems the target leveraged tokens, swaps the base asset for the zap asset and returns the zap asset to the caller.
     * @param leveragedTokenAddress The address of the target leveraged token to redeem.
     * @param leveragedTokenAmountIn The amount of the leveraged tokens to redeem.
     * @param minZapAssetAmountOut The minimum amount of the zap asset to receive (reverts otherwise).
     * @return zapAssetAmountOut The amount of zap asset received.
     */
    function redeem(
        address leveragedTokenAddress,
        uint256 leveragedTokenAmountIn,
        uint256 minZapAssetAmountOut
    ) external returns (uint256 zapAssetAmountOut);
}
