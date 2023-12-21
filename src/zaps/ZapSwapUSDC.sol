// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IZapSwap} from "../interfaces/IZapSwap.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IVelodromeRouter} from "../interfaces/velodrome/IVelodromeRouter.sol";
import {ILeveragedToken} from "../interfaces/ILeveragedToken.sol";

import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ZapSwapUSDC is IZapSwap {
    string internal _zapAsset;
    IERC20 internal immutable _USDC;
    IAddressProvider internal immutable _addressProvider;
    IVelodromeRouter internal immutable _velodromeRouter;
    address internal immutable _velodromeDefaultFactory;

    constructor(
        string memory zapAsset_,
        address usdcAddress_,
        address addressProvider_,
        address velodromeRouter_,
        address defaultFactory_
    ) {
        _zapAsset = zapAsset_;
        _USDC = IERC20(usdcAddress_);
        _addressProvider = IAddressProvider(addressProvider_);
        _velodromeRouter = IVelodromeRouter(velodromeRouter_);
        _velodromeDefaultFactory = defaultFactory_;
    }

    function zapAsset() public view override returns (string memory) {
        return _zapAsset;
    }

    function mint(
        address leveragedTokenAddress_,
        uint256 amountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) public override returns (uint256) {
        // Zero amountIn handling
        if (amountIn_ == 0) return 0;

        //  Verifying valid leveraged token address
        bool valid_ = _addressProvider.leveragedTokenFactory().isLeveragedToken(
            leveragedTokenAddress_
        );
        if (!valid_) revert InvalidAddress();

        // Get USDC from user
        _USDC.transferFrom(msg.sender, address(this), amountIn_);

        // Swap for baseAsset
        _swapUSDCForBaseAsset(amountIn_, 0);

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
            address(_USDC),
            amountIn_,
            leveragedTokenAmount_
        );

        return leveragedTokenAmount_;
    }

    function redeem(
        address leveragedTokenAddress_,
        uint256 leveragedTokenAmount_,
        uint256 minAmountOut_
    ) public override returns (uint256) {
        if (leveragedTokenAmount_ == 0) return 0;

        //  Verifying valid leveraged token address
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
        targetLeveragedToken.redeem(leveragedTokenAmount_, minAmountOut_);

        // Swap base asset into USDC
        _swapBaseAssetForUSDC(
            _addressProvider.baseAsset().balanceOf(address(this)),
            minAmountOut_
        );

        uint256 amountOut = _USDC.balanceOf(address(this));

        // Send USDC back to user
        _USDC.transfer(msg.sender, amountOut);

        emit Redeemed(
            msg.sender,
            leveragedTokenAddress_,
            leveragedTokenAmount_,
            address(_USDC),
            amountOut
        );

        // Return USDC received
        return amountOut;
    }

    function _swapUSDCForBaseAsset(
        uint256 amountIn_,
        uint256 minAmountOut_
    ) internal {
        IVelodromeRouter.Route[]
            memory routeList = new IVelodromeRouter.Route[](1);

        routeList[0] = IVelodromeRouter.Route(
            address(_USDC),
            address(_addressProvider.baseAsset()),
            true,
            _velodromeDefaultFactory
        );

        _USDC.approve(address(_velodromeRouter), amountIn_);

        _velodromeRouter.swapExactTokensForTokens(
            amountIn_,
            minAmountOut_,
            routeList,
            address(this),
            block.timestamp
        );
    }

    function _swapBaseAssetForUSDC(
        uint256 amountIn_,
        uint256 minAmountOut_
    ) internal {
        uint256 balanceBefore = _USDC.balanceOf(address(this));
        IVelodromeRouter.Route[]
            memory routeList = new IVelodromeRouter.Route[](1);

        routeList[0] = IVelodromeRouter.Route(
            address(_addressProvider.baseAsset()),
            address(_USDC),
            true,
            _velodromeDefaultFactory
        );

        _addressProvider.baseAsset().approve(
            address(_velodromeRouter),
            amountIn_
        );

        _velodromeRouter.swapExactTokensForTokens(
            amountIn_,
            minAmountOut_,
            routeList,
            address(this),
            block.timestamp
        );
        uint256 balanceAfter = _USDC.balanceOf(address(this));

        bool sufficient_ = (balanceAfter - balanceBefore) >= minAmountOut_;
        if (!sufficient_) revert InsufficientAmount();
    }
}
