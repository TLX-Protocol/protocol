// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IZapSwap} from "../interfaces/IZapSwap.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IVelodromeRouter} from "../interfaces/velodrome/IVelodromeRouter.sol";
import {ILeveragedToken} from "../interfaces/ILeveragedToken.sol";

import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ZapSwapDirect is IZapSwap {
    IERC20 internal immutable _zapAsset;
    IAddressProvider internal immutable _addressProvider;
    IVelodromeRouter internal immutable _velodromeRouter;
    address internal immutable _velodromeDefaultFactory;

    constructor(
        address zapAsset_,
        address addressProvider_,
        address velodromeRouter_,
        address defaultFactory_
    ) {
        _zapAsset = IERC20(zapAsset_);
        _addressProvider = IAddressProvider(addressProvider_);
        _velodromeRouter = IVelodromeRouter(velodromeRouter_);
        _velodromeDefaultFactory = defaultFactory_;
    }

    function zapAsset() public view override returns (address) {
        return address(_zapAsset);
    }

    function mint(
        address leveragedTokenAddress_,
        uint256 amountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) public override returns (uint256) {
        // Zero amountIn handling
        if (amountIn_ == 0) return 0;

        //  Verify valid leveraged token address
        bool valid_ = _addressProvider.leveragedTokenFactory().isLeveragedToken(
            leveragedTokenAddress_
        );
        if (!valid_) revert InvalidAddress();

        // Get USDC from user
        _zapAsset.transferFrom(msg.sender, address(this), amountIn_);

        // Swap for baseAsset
        _swapZapAssetForBaseAsset(amountIn_);

        uint256 baseAmountIn_ = _addressProvider.baseAsset().balanceOf(
            address(this)
        );

        ILeveragedToken targetLeveragedToken = ILeveragedToken(
            leveragedTokenAddress_
        );

        // Approve LT for baseAmount
        _addressProvider.baseAsset().approve(
            address(targetLeveragedToken),
            baseAmountIn_
        );

        // Mint leveraged tokens using baseAsset
        uint256 leveragedTokenAmount_ = targetLeveragedToken.mint(
            baseAmountIn_,
            minLeveragedTokenAmountOut_
        );

        // Transfer leveraged tokens to user
        targetLeveragedToken.transfer(msg.sender, leveragedTokenAmount_);

        emit Minted(
            msg.sender,
            leveragedTokenAddress_,
            address(_zapAsset),
            amountIn_,
            leveragedTokenAmount_
        );

        return leveragedTokenAmount_;
    }

    function redeem(
        address leveragedTokenAddress_,
        uint256 leveragedTokenAmount_,
        uint256 minZapAssetAmountOut_
    ) public override returns (uint256) {
        if (leveragedTokenAmount_ == 0) return 0;

        //  Verify valid leveraged token address
        bool valid_ = _addressProvider.leveragedTokenFactory().isLeveragedToken(
            leveragedTokenAddress_
        );
        if (!valid_) revert InvalidAddress();

        ILeveragedToken targetLeveragedToken = ILeveragedToken(
            leveragedTokenAddress_
        );

        // Transfer leveraged token from user to zap
        targetLeveragedToken.transferFrom(
            msg.sender,
            address(this),
            leveragedTokenAmount_
        );

        // Redeem leveraged token for baseAsset
        targetLeveragedToken.redeem(
            leveragedTokenAmount_,
            minZapAssetAmountOut_
        );

        // Swap baseAsset into zapAsset
        uint256 balanceBefore = _zapAsset.balanceOf(address(this));
        _swapBaseAssetForZapAsset(
            _addressProvider.baseAsset().balanceOf(address(this))
        );
        uint256 balanceOut = _zapAsset.balanceOf(address(this));

        bool sufficient_ = (balanceOut - balanceBefore) >=
            minZapAssetAmountOut_;
        if (!sufficient_) revert InsufficientAmount();

        // Send USDC back to user
        _zapAsset.transfer(msg.sender, balanceOut);

        emit Redeemed(
            msg.sender,
            leveragedTokenAddress_,
            leveragedTokenAmount_,
            address(_zapAsset),
            balanceOut
        );

        return balanceOut;
    }

    function _swapZapAssetForBaseAsset(uint256 amountIn_) internal virtual {
        IVelodromeRouter.Route[]
            memory routeList = new IVelodromeRouter.Route[](1);

        routeList[0] = IVelodromeRouter.Route(
            address(_zapAsset),
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

    function _swapBaseAssetForZapAsset(uint256 amountIn_) internal virtual {
        IVelodromeRouter.Route[]
            memory routeList = new IVelodromeRouter.Route[](1);

        routeList[0] = IVelodromeRouter.Route(
            address(_addressProvider.baseAsset()),
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
