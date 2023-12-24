// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ZapSwapDirect} from "./ZapSwapDirect.sol";

import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IVelodromeRouter} from "../interfaces/velodrome/IVelodromeRouter.sol";

contract ZapSwapIndirect is ZapSwapDirect {
    IERC20 internal immutable _bridgeAsset;

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
        _bridgeAsset = IERC20(bridgeAsset_);
    }

    function _swapZapAssetForBaseAsset(uint256 amountIn_) internal override {
        IVelodromeRouter.Route[]
            memory routeList = new IVelodromeRouter.Route[](2);

        routeList[0] = IVelodromeRouter.Route(
            address(_zapAsset),
            address(_bridgeAsset),
            true,
            _velodromeDefaultFactory
        );

        routeList[1] = IVelodromeRouter.Route(
            address(_bridgeAsset),
            address(_addressProvider.baseAsset()),
            true,
            _velodromeDefaultFactory
        );

        _zapAsset.approve(address(_velodromeRouter), amountIn_);

        _velodromeRouter.swapExactTokensForTokens(
            amountIn_,
            0,
            routeList,
            address(this),
            block.timestamp
        );
    }

    function _swapBaseAssetForZapAsset(uint256 amountIn_) internal override {
        IVelodromeRouter.Route[]
            memory routeList = new IVelodromeRouter.Route[](2);

        routeList[0] = IVelodromeRouter.Route(
            address(_addressProvider.baseAsset()),
            address(_bridgeAsset),
            true,
            _velodromeDefaultFactory
        );

        routeList[1] = IVelodromeRouter.Route(
            address(_bridgeAsset),
            address(_zapAsset),
            true,
            _velodromeDefaultFactory
        );

        _addressProvider.baseAsset().approve(
            address(_velodromeRouter),
            amountIn_
        );

        _velodromeRouter.swapExactTokensForTokens(
            amountIn_,
            0,
            routeList,
            address(this),
            block.timestamp
        );
    }
}
