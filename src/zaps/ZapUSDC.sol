// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

// DELETE
import "forge-std/console.sol";

import {Tokens} from "../libraries/Tokens.sol";

import {IZap} from "../interfaces/IZap.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IVelodromeRouter} from "../interfaces/velodrome/IVelodromeRouter.sol";
import {ILeveragedToken} from "../interfaces/ILeveragedToken.sol";

import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ZapUSDC is IZap {
    string private _name;
    IERC20 internal immutable _USDC;
    IERC20 internal immutable _SUSD;
    IAddressProvider internal immutable _addressProvider;
    IVelodromeRouter internal immutable _velodromeRouter;
    address internal immutable _velodromeDefaultFactory;

    constructor(
        string memory name_,
        address usdcAddress_,
        address susdAddress_,
        address addressProvider_,
        address velodromeRouter_,
        address defaultFactory_
    ) {
        _name = name_;
        _USDC = IERC20(usdcAddress_);
        _SUSD = IERC20(susdAddress_);
        _addressProvider = IAddressProvider(addressProvider_);
        _velodromeRouter = IVelodromeRouter(velodromeRouter_);
        _velodromeDefaultFactory = defaultFactory_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function mint(
        address leveragedTokenAddress_,
        uint256 amountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) public returns (uint256) {
        // Question: Are we using this instead of an error because of efficiency?
        if (amountIn_ == 0) return 0;

        //  Verifying valid leveraged token address
        bool valid_ = _addressProvider.leveragedTokenFactory().isLeveragedToken(
            leveragedTokenAddress_
        );
        if (!valid_) revert InvalidAddress();

        // Get USDC from user
        _USDC.transferFrom(msg.sender, address(this), amountIn_);

        // Swap for sUSD
        // Question: Are we sure about minAmountZero here? What about applying a max slippage?
        _swapUsdcForSusd(amountIn_, 0);

        // Question: Can we work with _SUSD.balanceOf(address(this))) here? Or is there a risk that the zap holds more?
        uint256 baseAmountIn_ = _SUSD.balanceOf(address(this));

        // Question: Should this have a specified visibility?
        ILeveragedToken targetLeveragedToken = ILeveragedToken(
            leveragedTokenAddress_
        );

        // Approve LT for baseAmount
        _SUSD.approve(address(targetLeveragedToken), baseAmountIn_);

        // Question: The leveraged token is already checking for the minAmountOut, so it would be unnecessary to check again right?
        uint256 leveragedTokenAmount_ = targetLeveragedToken.mint(
            baseAmountIn_,
            minLeveragedTokenAmountOut_
        );

        targetLeveragedToken.transfer(msg.sender, leveragedTokenAmount_);

        emit Minted(msg.sender, baseAmountIn_, leveragedTokenAmount_);

        return leveragedTokenAmount_;
    }

    function _swapUsdcForSusd(
        uint256 amountIn,
        uint256 minAmountOut
    ) internal returns (uint256) {
        // Consider using a max % slippage value, rather than minAmountOut?
        IVelodromeRouter.Route[]
            memory routeList = new IVelodromeRouter.Route[](1);

        routeList[0] = IVelodromeRouter.Route(
            address(_USDC),
            address(_SUSD),
            true,
            _velodromeDefaultFactory
        );

        _USDC.approve(address(_velodromeRouter), amountIn);

        _velodromeRouter.swapExactTokensForTokens(
            amountIn,
            minAmountOut,
            routeList,
            address(this),
            block.timestamp
        );

        return 0;
    }
}
