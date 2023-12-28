// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IZapSwap} from "../interfaces/IZapSwap.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IVelodromeRouter} from "../interfaces/velodrome/IVelodromeRouter.sol";
import {ILeveragedToken} from "../interfaces/ILeveragedToken.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Errors} from "../libraries/Errors.sol";

contract ZapSwapDirect is IZapSwap {
    IERC20 internal immutable _zapAsset;
    IAddressProvider internal immutable _addressProvider;
    IVelodromeRouter internal immutable _velodromeRouter;
    address internal immutable _velodromeFactory;
    bool internal immutable _stable;

    constructor(
        address zapAsset_,
        address addressProvider_,
        address velodromeRouter_,
        address velodromeFactory_,
        bool stable_
    ) {
        _zapAsset = IERC20(zapAsset_);
        _addressProvider = IAddressProvider(addressProvider_);
        _velodromeRouter = IVelodromeRouter(velodromeRouter_);
        _velodromeFactory = velodromeFactory_;
        _stable = stable_;

        // Approve velodrome router once to minimize gas costs
        _zapAsset.approve(address(_velodromeRouter), type(uint256).max);
        _addressProvider.baseAsset().approve(
            address(_velodromeRouter),
            type(uint256).max
        );
    }

    function mint(
        address leveragedTokenAddress_,
        uint256 zapAssetAmountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) public override returns (uint256) {
        if (zapAssetAmountIn_ == 0) return 0;

        //  Verifying valid leveraged token address
        bool valid_ = _addressProvider.leveragedTokenFactory().isLeveragedToken(
            leveragedTokenAddress_
        );
        if (!valid_) revert Errors.InvalidAddress();

        IERC20 baseAsset_ = _addressProvider.baseAsset();

        // Receiving zapAsset from user
        _zapAsset.transferFrom(msg.sender, address(this), zapAssetAmountIn_);

        // Swapping zapAsset for baseAsset
        _swapAssetForAsset(
            zapAssetAmountIn_,
            address(_zapAsset),
            address(baseAsset_)
        );

        uint256 baseAmountIn_ = baseAsset_.balanceOf(address(this));

        // Minting leveraged tokens using baseAsset
        ILeveragedToken targetLeveragedToken = ILeveragedToken(
            leveragedTokenAddress_
        );
        baseAsset_.approve(address(targetLeveragedToken), baseAmountIn_);
        uint256 leveragedTokenAmountOut_ = targetLeveragedToken.mint(
            baseAmountIn_,
            minLeveragedTokenAmountOut_
        );

        // Transferring leveraged tokens to user
        targetLeveragedToken.transfer(msg.sender, leveragedTokenAmountOut_);
        emit Minted(
            msg.sender,
            leveragedTokenAddress_,
            address(_zapAsset),
            zapAssetAmountIn_,
            leveragedTokenAmountOut_
        );

        return leveragedTokenAmountOut_;
    }

    function redeem(
        address leveragedTokenAddress_,
        uint256 leveragedTokenAmountIn_,
        uint256 minZapAssetAmountOut_
    ) public override returns (uint256) {
        if (leveragedTokenAmountIn_ == 0) return 0;

        //  Verifying valid leveraged token address
        bool valid_ = _addressProvider.leveragedTokenFactory().isLeveragedToken(
            leveragedTokenAddress_
        );
        if (!valid_) revert Errors.InvalidAddress();

        // Transferring leveraged token from user to zap
        ILeveragedToken targetLeveragedToken = ILeveragedToken(
            leveragedTokenAddress_
        );
        targetLeveragedToken.transferFrom(
            msg.sender,
            address(this),
            leveragedTokenAmountIn_
        );

        // Redeeming leveraged token for baseAsset
        targetLeveragedToken.redeem(
            leveragedTokenAmountIn_,
            minZapAssetAmountOut_
        );

        // Swapping baseAsset for zapAsset
        IERC20 baseAsset_ = _addressProvider.baseAsset();
        _swapAssetForAsset(
            baseAsset_.balanceOf(address(this)),
            address(baseAsset_),
            address(_zapAsset)
        );
        uint256 zapAssetAmountOut = _zapAsset.balanceOf(address(this));

        // Verifying sufficient amount
        bool sufficient_ = zapAssetAmountOut >= minZapAssetAmountOut_;
        if (!sufficient_) revert Errors.InsufficientAmount();

        // Send zapAsset back to user
        _zapAsset.transfer(msg.sender, zapAssetAmountOut);

        emit Redeemed(
            msg.sender,
            leveragedTokenAddress_,
            leveragedTokenAmountIn_,
            address(_zapAsset),
            zapAssetAmountOut
        );

        return zapAssetAmountOut;
    }

    function zapAsset() public view override returns (address) {
        return address(_zapAsset);
    }

    function _swapAssetForAsset(
        uint256 amountIn_,
        address assetIn_,
        address assetOut_
    ) internal virtual {
        // Setting the swap route
        IVelodromeRouter.Route[]
            memory routeList = new IVelodromeRouter.Route[](1);
        routeList[0] = IVelodromeRouter.Route(
            assetIn_,
            assetOut_,
            _stable,
            _velodromeFactory
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
