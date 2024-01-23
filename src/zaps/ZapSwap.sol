// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IZapSwap} from "../interfaces/IZapSwap.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IVelodromeRouter} from "../interfaces/exchanges/IVelodromeRouter.sol";
import {IUniswapRouter} from "../interfaces/exchanges/IUniswapRouter.sol";
import {ILeveragedToken} from "../interfaces/ILeveragedToken.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {Errors} from "../libraries/Errors.sol";

contract ZapSwap is IZapSwap, Ownable {
    IAddressProvider internal immutable _addressProvider;
    IVelodromeRouter internal immutable _velodromeRouter;
    address internal immutable _velodromeFactory;
    IUniswapRouter internal immutable _uniswapRouter;

    // Mapping zapAssets to their respective swapData
    mapping(address => SwapData) internal _swapDB;
    // Array keeping track of all supported zapAssets
    address[] internal _supportedAssets;

    constructor(
        address addressProvider_,
        address velodromeRouter_,
        address velodromeFactory_,
        address uniswapRouter_
    ) {
        _addressProvider = IAddressProvider(addressProvider_);
        _velodromeRouter = IVelodromeRouter(velodromeRouter_);
        _velodromeFactory = velodromeFactory_;
        _uniswapRouter = IUniswapRouter(uniswapRouter_);

        // Approve velodrome router for base asset
        _addressProvider.baseAsset().approve(
            address(_velodromeRouter),
            type(uint256).max
        );
    }

    function setAssetSwapData(
        address zapAsset_,
        SwapData memory swapData_
    ) external override onlyOwner {
        // Verifying that the bridge asset for uniswap is supported on velodrome
        if (swapData_.swapZapAssetOnUni) {
            bool _bridgeSupported = _swapDB[swapData_.bridgeAsset].supported &&
                !_swapDB[swapData_.bridgeAsset].swapZapAssetOnUni;
            if (!_bridgeSupported) {
                revert BridgeAssetNotSupported();
            }
            // Approving the uniswap router for zap and bridge asset
            IERC20(swapData_.bridgeAsset).approve(
                address(_uniswapRouter),
                type(uint256).max
            );
            IERC20(zapAsset_).approve(
                address(_uniswapRouter),
                type(uint256).max
            );
        } else {
            IERC20(zapAsset_).approve(
                address(_velodromeRouter),
                type(uint256).max
            );
        }

        // Adding zap asset to supported assets only if it is a new asset
        if (!_swapDB[zapAsset_].supported) {
            _supportedAssets.push(zapAsset_);
        }

        // Setting the swapPath for the zapAsset
        _swapDB[zapAsset_] = swapData_;
    }

    function mint(
        address zapAssetAddress_,
        address leveragedTokenAddress_,
        uint256 zapAssetAmountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) public override returns (uint256) {
        // Swap data of zap asset
        SwapData memory zapAssetSwapData_ = _swapDB[zapAssetAddress_];

        // Verifying asset is supported
        if (!zapAssetSwapData_.supported) {
            revert UnsupportedAsset();
        }

        // Verifying amount in is over zero
        if (zapAssetAmountIn_ == 0) return 0;

        //  Verifying valid leveraged token address
        bool valid_ = _addressProvider.leveragedTokenFactory().isLeveragedToken(
            leveragedTokenAddress_
        );
        if (!valid_) revert Errors.InvalidAddress();

        IERC20 baseAsset_ = _addressProvider.baseAsset();
        IERC20 zapAsset_ = IERC20(zapAssetAddress_);

        // Receiving zap asset from user
        zapAsset_.transferFrom(msg.sender, address(this), zapAssetAmountIn_);

        // Swap zap asset for base asset based on swap data
        _swapAsset(
            zapAssetAmountIn_,
            zapAssetAddress_,
            address(baseAsset_),
            zapAssetSwapData_,
            true
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
            zapAssetAddress_,
            zapAssetAmountIn_,
            leveragedTokenAmountOut_
        );

        return leveragedTokenAmountOut_;
    }

    function redeem(
        address zapAssetAddress_,
        address leveragedTokenAddress_,
        uint256 leveragedTokenAmountIn_,
        uint256 minZapAssetAmountOut_
    ) public override returns (uint256) {
        // Swap data of zap asset
        SwapData memory zapAssetSwapData_ = _swapDB[zapAssetAddress_];

        // Verifying that asset is supported
        if (!zapAssetSwapData_.supported) {
            revert UnsupportedAsset();
        }

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

        // Redeeming leveraged token for base asset
        targetLeveragedToken.redeem(
            leveragedTokenAmountIn_,
            minZapAssetAmountOut_
        );

        IERC20 baseAsset_ = _addressProvider.baseAsset();
        IERC20 zapAsset_ = IERC20(zapAssetAddress_);
        uint256 baseAssetAmountIn_ = baseAsset_.balanceOf(address(this));

        // Swapping base asset for zap asset based on swap data
        _swapAsset(
            baseAssetAmountIn_,
            address(baseAsset_),
            zapAssetAddress_,
            zapAssetSwapData_,
            false
        );

        uint256 zapAssetAmountOut = zapAsset_.balanceOf(address(this));

        // Verifying sufficient amount
        bool sufficient_ = zapAssetAmountOut >= minZapAssetAmountOut_;
        if (!sufficient_) revert Errors.InsufficientAmount();

        // Sending the zap asset back to the user
        zapAsset_.transfer(msg.sender, zapAssetAmountOut);

        emit Redeemed(
            msg.sender,
            leveragedTokenAddress_,
            leveragedTokenAmountIn_,
            zapAssetAddress_,
            zapAssetAmountOut
        );

        return zapAssetAmountOut;
    }

    function swapData(
        address zapAsset_
    ) public view override returns (SwapData memory) {
        return _swapDB[zapAsset_];
    }

    function supportedZapAssets()
        public
        view
        override
        returns (address[] memory)
    {
        return _supportedAssets;
    }

    function _swapAsset(
        uint256 amountIn_,
        address assetIn_,
        address assetOut_,
        SwapData memory swapData_,
        bool zapAssetForBaseAsset_
    ) internal {
        if (!swapData_.swapZapAssetOnUni) {
            _swapOnVelodrome(
                amountIn_,
                assetIn_,
                assetOut_,
                swapData_,
                zapAssetForBaseAsset_
            );
        } else {
            _swapUniAndVelodrome(
                amountIn_,
                assetIn_,
                assetOut_,
                swapData_,
                zapAssetForBaseAsset_
            );
        }
    }

    function _swapOnVelodrome(
        uint256 amountIn_,
        address assetIn_,
        address assetOut_,
        SwapData memory swapData_,
        bool zapAssetForBaseAsset_
    ) internal {
        if (swapData_.direct) {
            // Swapping directly
            IVelodromeRouter.Route[]
                memory routeList = new IVelodromeRouter.Route[](1);
            routeList[0] = IVelodromeRouter.Route(
                assetIn_,
                assetOut_,
                swapData_.zapAssetSwapStable,
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
        } else {
            // Swapping indirectly

            // Assigning the first and second pool stability based on swap direction
            bool firstStable;
            bool secondStable;

            if (zapAssetForBaseAsset_) {
                firstStable = swapData_.zapAssetSwapStable;
                secondStable = swapData_.baseAssetSwapStable;
            } else {
                firstStable = swapData_.baseAssetSwapStable;
                secondStable = swapData_.zapAssetSwapStable;
            }

            // Setting the swap route
            IVelodromeRouter.Route[]
                memory routeList = new IVelodromeRouter.Route[](2);
            routeList[0] = IVelodromeRouter.Route(
                assetIn_,
                swapData_.bridgeAsset,
                firstStable,
                _velodromeFactory
            );
            routeList[1] = IVelodromeRouter.Route(
                swapData_.bridgeAsset,
                assetOut_,
                secondStable,
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

    function _swapUniAndVelodrome(
        uint256 amountIn_,
        address assetIn_,
        address assetOut_,
        SwapData memory swapData_,
        bool zapAssetForBaseAsset_
    ) internal {
        address bridgeAsset = swapData_.bridgeAsset;
        SwapData memory swapDataBridgeAsset = _swapDB[bridgeAsset];

        // Verifying direction
        if (zapAssetForBaseAsset_) {
            // Zap asset for bridge asset on UniSwap
            IUniswapRouter.ExactInputSingleParams memory params = IUniswapRouter
                .ExactInputSingleParams(
                    assetIn_,
                    bridgeAsset,
                    swapData_.uniPoolFee,
                    address(this),
                    block.timestamp,
                    amountIn_,
                    0,
                    0
                );

            _uniswapRouter.exactInputSingle(params);

            // Bridge asset for base asset on Velodrome
            _swapOnVelodrome(
                IERC20(bridgeAsset).balanceOf(address(this)),
                bridgeAsset,
                assetOut_,
                swapDataBridgeAsset,
                zapAssetForBaseAsset_
            );
        } else {
            // Base asset for bridge asset on Velodrome
            _swapOnVelodrome(
                amountIn_,
                assetIn_,
                bridgeAsset,
                swapDataBridgeAsset,
                zapAssetForBaseAsset_
            );
            // Bridge asset for zap asset on UniSwap
            IUniswapRouter.ExactInputSingleParams memory params = IUniswapRouter
                .ExactInputSingleParams(
                    bridgeAsset,
                    assetOut_,
                    swapData_.uniPoolFee,
                    address(this),
                    block.timestamp,
                    IERC20(bridgeAsset).balanceOf(address(this)),
                    0,
                    0
                );
            _uniswapRouter.exactInputSingle(params);
        }
    }
}
