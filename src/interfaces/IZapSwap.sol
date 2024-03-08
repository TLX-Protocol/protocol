// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IZapSwap {
    struct SwapData {
        bool supported;
        bool direct;
        address bridgeAsset;
        bool zapAssetSwapStable;
        bool baseAssetSwapStable;
        address zapAssetFactory;
        address baseAssetFactory;
        bool swapZapAssetOnUni;
        uint24 uniPoolFee;
    }

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
    event AssetSwapDataUpdated(address indexed zapAsset, SwapData swapData);

    error UnsupportedAsset();
    error BridgeAssetNotSupported();
    error BridgeAssetDependency(address dependentZapAsset);

    /**
     * @notice Sets the swap data for a zap asset.
     * @param zapAsset The address of the new zap asset.
     * @param swapData The swap data describing the swap route.
     */
    function setAssetSwapData(
        address zapAsset,
        SwapData memory swapData
    ) external;

    /**
     * @notice Removes an asset from supported zap assets.
     * @param zapAsset The address of the zap asset to be removed.
     */
    function removeAssetSwapData(address zapAsset) external;

    /**
     * @notice Returns the swap data of a zap asset.
     * @param zapAsset The address of the zap asset.
     * @return swapData The swap data of the zap asset.
     */
    function swapData(
        address zapAsset
    ) external returns (SwapData memory swapData);

    /**
     * @notice Returns all assets supported by the zap.
     * @return assets An array of all assets supported by the zap.
     */
    function supportedZapAssets() external returns (address[] memory assets);

    /**
     * @notice Swaps the zap asset for the base asset and mints the target leveraged tokens for the caller.
     * @param zapAssetAddress The address of the asset used for minting.
     * @param leveragedTokenAddress Address of target leveraged token to mint.
     * @param zapAssetAmountIn The amount of the zap asset to mint with.
     * @param minLeveragedTokenAmountOut The minimum amount of leveraged tokens to receive (reverts otherwise).
     * @return leveragedTokenAmountOut The amount of leveraged tokens minted.
     */
    function mint(
        address zapAssetAddress,
        address leveragedTokenAddress,
        uint256 zapAssetAmountIn,
        uint256 minLeveragedTokenAmountOut
    ) external returns (uint256 leveragedTokenAmountOut);

    /**
     * @notice Redeems the target leveraged tokens, swaps the base asset for the zap asset and returns the zap asset to the caller.
     * @param zapAssetAddress The address of the asset received upon redeeming.
     * @param leveragedTokenAddress The address of the target leveraged token to redeem.
     * @param leveragedTokenAmountIn The amount of the leveraged tokens to redeem.
     * @param minZapAssetAmountOut The minimum amount of the zap asset to receive (reverts otherwise).
     * @return zapAssetAmountOut The amount of zap asset received.
     */
    function redeem(
        address zapAssetAddress,
        address leveragedTokenAddress,
        uint256 leveragedTokenAmountIn,
        uint256 minZapAssetAmountOut
    ) external returns (uint256 zapAssetAmountOut);
}
