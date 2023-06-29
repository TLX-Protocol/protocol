// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {IOracle} from "./interfaces/IOracle.sol";
import {IDerivativesHandler} from "./interfaces/IDerivativesHandler.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IRouter} from "./interfaces/vendor/gmx/IRouter.sol";
import {IPositionRouter} from "./interfaces/vendor/gmx/IPositionRouter.sol";

contract GmxDerivativesHandler is IDerivativesHandler, Ownable {
    using SafeERC20 for IERC20;
    using ScaledNumber for uint256;

    address internal immutable _addressProvider;
    address internal immutable _positionRouter;
    address internal immutable _router;
    address internal immutable _baseToken;

    uint256 public imprecisionThreshold;

    constructor(
        address addressProvider_,
        address positionRouter_,
        address router_,
        address baseToken_
    ) {
        _addressProvider = addressProvider_;
        _positionRouter = positionRouter_;
        _router = router_;
        _baseToken = baseToken_;

        imprecisionThreshold = 0.01e18;
    }

    function initialize() external {
        IRouter(_router).approvePlugin(_positionRouter);
        IERC20(_baseToken).safeApprove(_positionRouter, type(uint256).max);
    }

    function createPosition(
        address targetToken_,
        uint256 baseAmount_,
        uint256 targetAmount_,
        bool isLong_
    ) external {
        // TODO Check we don't have one open already?

        IOracle oracle_ = IOracle(IAddressProvider(_addressProvider).oracle());
        uint256 targetPrice_ = oracle_.getUsdPrice(targetToken_);
        uint256 imprecision_ = targetPrice_.mul(imprecisionThreshold);
        uint256 acceptablePrice_ = isLong_
            ? targetPrice_ + imprecision_
            : targetPrice_ - imprecision_;
        IPositionRouter positionRouter_ = IPositionRouter(_positionRouter);
        address[] memory path_ = new address[](1);
        path_[0] = _baseToken;
        positionRouter_.createIncreasePosition(
            path_,
            targetToken_,
            baseAmount_,
            0,
            targetAmount_.mul(targetPrice_),
            isLong_,
            acceptablePrice_,
            positionRouter_.minExecutionFee(),
            bytes32(""), // TODO Earn referrals
            address(0)
        );
    }

    function updateImprecisionThreshold(uint256 threshold_) external onlyOwner {
        imprecisionThreshold = threshold_;
    }
}
