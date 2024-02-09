// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IZapSwap} from "../interfaces/IZapSwap.sol";

import {Contracts} from "./Contracts.sol";
import {Tokens} from "./Tokens.sol";

library ZapAssetRoutes {
    function zapAssetRoutes()
        internal
        pure
        returns (address[5] memory, IZapSwap.SwapData[] memory)
    {
        // Zap assets
        address[5] memory zapAssets_;
        // Swap routes
        IZapSwap.SwapData[] memory zapAssetRoutes_ = new IZapSwap.SwapData[](5);

        address veloDefaultFactory_ = Contracts.VELODROME_DEFAULT_FACTORY;

        // USDC.e
        zapAssets_[0] = Tokens.USDCE;
        zapAssetRoutes_[0] = IZapSwap.SwapData({
            supported: true,
            direct: true,
            bridgeAsset: address(0),
            zapAssetSwapStable: true,
            baseAssetSwapStable: true,
            zapAssetFactory: veloDefaultFactory_,
            baseAssetFactory: veloDefaultFactory_,
            swapZapAssetOnUni: false,
            uniPoolFee: 0
        });

        // USDT
        zapAssets_[1] = Tokens.USDT;
        zapAssetRoutes_[1] = IZapSwap.SwapData({
            supported: true,
            direct: false,
            bridgeAsset: Tokens.USDCE,
            zapAssetSwapStable: true,
            baseAssetSwapStable: true,
            zapAssetFactory: veloDefaultFactory_,
            baseAssetFactory: veloDefaultFactory_,
            swapZapAssetOnUni: false,
            uniPoolFee: 0
        });

        // DAI
        zapAssets_[2] = Tokens.DAI;
        zapAssetRoutes_[2] = IZapSwap.SwapData({
            supported: true,
            direct: false,
            bridgeAsset: Tokens.USDCE,
            zapAssetSwapStable: true,
            baseAssetSwapStable: true,
            zapAssetFactory: veloDefaultFactory_,
            baseAssetFactory: veloDefaultFactory_,
            swapZapAssetOnUni: false,
            uniPoolFee: 0
        });

        // USDC
        zapAssets_[3] = Tokens.USDC;
        zapAssetRoutes_[3] = IZapSwap.SwapData({
            supported: true,
            direct: false,
            bridgeAsset: Tokens.USDCE,
            zapAssetSwapStable: true,
            baseAssetSwapStable: true,
            zapAssetFactory: veloDefaultFactory_,
            baseAssetFactory: veloDefaultFactory_,
            swapZapAssetOnUni: true,
            uniPoolFee: 100
        });

        // WETH
        zapAssets_[4] = Tokens.WETH;
        zapAssetRoutes_[4] = IZapSwap.SwapData({
            supported: true,
            direct: false,
            bridgeAsset: Tokens.USDCE,
            zapAssetSwapStable: true,
            baseAssetSwapStable: true,
            zapAssetFactory: veloDefaultFactory_,
            baseAssetFactory: veloDefaultFactory_,
            swapZapAssetOnUni: true,
            uniPoolFee: 500
        });

        return (zapAssets_, zapAssetRoutes_);
    }
}
