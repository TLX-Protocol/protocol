// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {IRouter} from "./interfaces/vendor/gmx/IRouter.sol";

contract GmxDerivativesHandler {
    using SafeERC20 for IERC20;

    address internal immutable _positionRouter;
    address internal immutable _router;
    address internal immutable _baseToken;

    constructor(address positionRouter_, address router_, address baseToken_) {
        _positionRouter = positionRouter_;
        _router = router_;
        _baseToken = baseToken_;
    }

    function initialize() external {
        IRouter(_router).approvePlugin(_positionRouter);
        IERC20(_baseToken).safeApprove(_router, type(uint256).max);
    }
}
