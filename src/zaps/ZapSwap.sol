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
    IUniswapRouter internal immutable _uniswapRouter;

    // Mapping zapAssets to their respective swapData
    mapping(address => SwapData) internal _swapDB;
    // Array keeping track of all supported zap assets
    address[] internal _supportedZapAssets;

    constructor(
        address addressProvider_,
        address velodromeRouter_,
        address uniswapRouter_
    ) {
        _addressProvider = IAddressProvider(addressProvider_);
        _velodromeRouter = IVelodromeRouter(velodromeRouter_);
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
            SwapData memory bridgeData_ = _swapDB[swapData_.bridgeAsset];
            bool bridgeSupported_ = bridgeData_.supported &&
                !bridgeData_.swapZapAssetOnUni;
            if (!bridgeSupported_) {
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
            // Approving the velodrome router for zap asset
            IERC20(zapAsset_).approve(
                address(_velodromeRouter),
                type(uint256).max
            );
        }

        // Adding zap asset to supported assets only if it is a new asset
        if (!_swapDB[zapAsset_].supported) {
            _supportedZapAssets.push(zapAsset_);
        }

        // Setting the swapPath for the zapAsset
        _swapDB[zapAsset_] = swapData_;
    }

    function removeAssetSwapData(
        address zapAsset_
    ) external override onlyOwner {
        // Reverting if asset is not supported or required as a bridge asset
        // Returning its index in the _supportedZapAssets array if validated
        uint256 idx_ = _validateAssetRemoval(zapAsset_);

        // Setting the zap asset to unsupported
        _swapDB[zapAsset_].supported = false;

        // Removing the zap asset from supported assets array
        _supportedZapAssets[idx_] = _supportedZapAssets[
            _supportedZapAssets.length - 1
        ];
        _supportedZapAssets.pop();
    }

    function mint(
        address zapAssetAddress_,
        address leveragedTokenAddress_,
        uint256 zapAssetAmountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) public override returns (uint256) {
        // If amountIn is zero exit mint and return zero
        if (zapAssetAmountIn_ == 0) return 0;

        // Swap data of zap asset
        SwapData memory zapAssetSwapData_ = _swapDB[zapAssetAddress_];

        // Verifying that zap asset is supported and the leveraged token address is valid
        _validateZap(zapAssetSwapData_, leveragedTokenAddress_);

        IERC20 baseAsset_ = _addressProvider.baseAsset();
        IERC20 zapAsset_ = IERC20(zapAssetAddress_);

        // Receiving zap asset from user
        zapAsset_.transferFrom(msg.sender, address(this), zapAssetAmountIn_);

        // Swapping zap asset for base asset based on swap data
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
        baseAsset_.approve(leveragedTokenAddress_, baseAmountIn_);
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
        // If amountIn is zero exit redeem and return zero
        if (leveragedTokenAmountIn_ == 0) return 0;

        // Swap data of zap asset
        SwapData memory zapAssetSwapData_ = _swapDB[zapAssetAddress_];

        // Verifying that zap asset is supported and the leveraged token address is valid
        _validateZap(zapAssetSwapData_, leveragedTokenAddress_);

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

        uint256 zapAssetAmountOut_ = zapAsset_.balanceOf(address(this));

        // Verifying sufficient amount
        bool sufficient_ = zapAssetAmountOut_ >= minZapAssetAmountOut_;
        if (!sufficient_) revert Errors.InsufficientAmount();

        // Sending the zap asset back to the user
        zapAsset_.transfer(msg.sender, zapAssetAmountOut_);

        emit Redeemed(
            msg.sender,
            leveragedTokenAddress_,
            leveragedTokenAmountIn_,
            zapAssetAddress_,
            zapAssetAmountOut_
        );

        return zapAssetAmountOut_;
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
        return _supportedZapAssets;
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
            _swapOnUniAndVelodrome(
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
                memory routeList_ = new IVelodromeRouter.Route[](1);
            routeList_[0] = IVelodromeRouter.Route(
                assetIn_,
                assetOut_,
                swapData_.zapAssetSwapStable,
                swapData_.zapAssetFactory
            );

            // Executing the swap
            _velodromeRouter.swapExactTokensForTokens(
                amountIn_,
                0,
                routeList_,
                address(this),
                block.timestamp
            );
        } else {
            // Swapping indirectly

            // Assigning the first and second pool stability and factory based on swap direction
            bool firstStable_;
            address firstFactory_;
            bool secondStable_;
            address secondFactory_;

            if (zapAssetForBaseAsset_) {
                firstStable_ = swapData_.zapAssetSwapStable;
                firstFactory_ = swapData_.zapAssetFactory;
                secondStable_ = swapData_.baseAssetSwapStable;
                secondFactory_ = swapData_.baseAssetFactory;
            } else {
                firstStable_ = swapData_.baseAssetSwapStable;
                firstFactory_ = swapData_.baseAssetFactory;
                secondStable_ = swapData_.zapAssetSwapStable;
                secondFactory_ = swapData_.zapAssetFactory;
            }

            // Setting the swap route
            IVelodromeRouter.Route[]
                memory routeList_ = new IVelodromeRouter.Route[](2);
            routeList_[0] = IVelodromeRouter.Route(
                assetIn_,
                swapData_.bridgeAsset,
                firstStable_,
                firstFactory_
            );
            routeList_[1] = IVelodromeRouter.Route(
                swapData_.bridgeAsset,
                assetOut_,
                secondStable_,
                secondFactory_
            );

            // Executing the swap
            _velodromeRouter.swapExactTokensForTokens(
                amountIn_,
                0,
                routeList_,
                address(this),
                block.timestamp
            );
        }
    }

    function _swapOnUni(
        uint256 amountIn_,
        address assetIn_,
        address assetOut_,
        uint24 poolFee_
    ) internal {
        IUniswapRouter.ExactInputSingleParams memory params_ = IUniswapRouter
            .ExactInputSingleParams(
                assetIn_,
                assetOut_,
                poolFee_,
                address(this),
                block.timestamp,
                amountIn_,
                0,
                0
            );

        _uniswapRouter.exactInputSingle(params_);
    }

    function _swapOnUniAndVelodrome(
        uint256 amountIn_,
        address assetIn_,
        address assetOut_,
        SwapData memory swapData_,
        bool zapAssetForBaseAsset_
    ) internal {
        address bridgeAsset_ = swapData_.bridgeAsset;
        SwapData memory swapDataBridgeAsset_ = _swapDB[bridgeAsset_];

        // Verifying direction
        if (zapAssetForBaseAsset_) {
            // Swap zap asset for bridge asset on UniSwap
            _swapOnUni(amountIn_, assetIn_, bridgeAsset_, swapData_.uniPoolFee);

            // Swap bridge asset for base asset on Velodrome
            _swapOnVelodrome(
                IERC20(bridgeAsset_).balanceOf(address(this)),
                bridgeAsset_,
                assetOut_,
                swapDataBridgeAsset_,
                zapAssetForBaseAsset_
            );
        } else {
            // Swap base asset for bridge asset on Velodrome
            _swapOnVelodrome(
                amountIn_,
                assetIn_,
                bridgeAsset_,
                swapDataBridgeAsset_,
                zapAssetForBaseAsset_
            );

            // Swap bridge asset for zap asset on UniSwap
            _swapOnUni(
                IERC20(bridgeAsset_).balanceOf(address(this)),
                bridgeAsset_,
                assetOut_,
                swapData_.uniPoolFee
            );
        }
    }

    function _validateZap(
        SwapData memory zapAssetSwapData_,
        address leveragedTokenAddress_
    ) internal view {
        // Verifying that the asset is supported
        if (!zapAssetSwapData_.supported) {
            revert UnsupportedAsset();
        }

        //  Verifying valid leveraged token address
        bool valid_ = _addressProvider.leveragedTokenFactory().isLeveragedToken(
            leveragedTokenAddress_
        );
        if (!valid_) revert Errors.InvalidAddress();
    }

    function _validateAssetRemoval(
        address zapAssetToRemove_
    ) internal view returns (uint256) {
        uint256 numAssets_ = _supportedZapAssets.length;
        uint256 idx_ = numAssets_; // invalid index; used to determine whether zap asset is supported

        // Iterating through supported zap assets
        for (uint256 i_ = 0; i_ < numAssets_; i_++) {
            address asset_ = _supportedZapAssets[i_];
            if (asset_ == zapAssetToRemove_) {
                // Capturing the index of the zap asset to be removed
                idx_ = i_;
            } else if (_swapDB[asset_].bridgeAsset == zapAssetToRemove_) {
                // Reverting if the zap asset to be removed is needed as a bridge asset
                revert BridgeAssetDependency(asset_);
            }
        }
        // Reverting if the zap asset is not supported, else returning its index
        if (idx_ == numAssets_) {
            revert UnsupportedAsset();
        } else {
            return (idx_);
        }
    }
}
