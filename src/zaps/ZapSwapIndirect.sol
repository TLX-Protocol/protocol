// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ZapSwapDirect} from "./ZapSwapDirect.sol";

import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IVelodromeRouter} from "../interfaces/velodrome/IVelodromeRouter.sol";

contract ZapSwapIndirect is ZapSwapDirect {
    address internal immutable _bridgeAsset;

    constructor(
        address zapAsset_,
        address addressProvider_,
        address velodromeRouter_,
        address defaultFactory_,
        address bridgeAsset_
    )
        ZapSwapDirect(
            zapAsset_,
            addressProvider_,
            velodromeRouter_,
            defaultFactory_
        )
    {
        // Set the bridgeAsset used in the route of an indirect swap
        _bridgeAsset = bridgeAsset_;
    }

    function _swapAssetForAsset(
        uint256 amountIn_,
        address assetIn_,
        address assetOut_
    ) internal override {
        // Setting the swap route
        IVelodromeRouter.Route[]
            memory routeList = new IVelodromeRouter.Route[](2);
        routeList[0] = IVelodromeRouter.Route(
            assetIn_,
            _bridgeAsset,
            true,
            _velodromeDefaultFactory
        );
        routeList[1] = IVelodromeRouter.Route(
            _bridgeAsset,
            assetOut_,
            true,
            _velodromeDefaultFactory
        );

        // Executing the swap
        _velodromeRouter.swapExactTokensForTokens(
            amountIn_,
            0,
            routeList,
            address(this),
            block.timestamp
        );
    }
}
