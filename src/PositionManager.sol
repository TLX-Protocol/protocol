// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IPositionManager} from "./interfaces/IPositionManager.sol";

contract PositionManager is IPositionManager {
    // TODO Add events to all functions
    address public immutable override baseAsset;
    address public immutable override targetAsset;

    constructor(address baseAsset_, address targetAsset_) {
        baseAsset = baseAsset_;
        targetAsset = targetAsset_;
    }

    function mintAmountIn(
        address /* leveragedToken_ */,
        uint256 /* baseAmountIn_ */,
        uint256 /* minLeveragedTokenAmountOut_ */
    ) external override returns (uint256) {
        // TODO implement
        return 0;
    }

    function mintAmountOut(
        address /* leveragedToken_ */,
        uint256 /* leveragedTokenAmountOut_ */,
        uint256 /* maxBaseAmountIn_ */
    ) external override returns (uint256) {
        // TODO implement
        return 0;
    }

    function burn(
        address /* leveragedToken_ */,
        uint256 /* leveragedTokenAmount_ */,
        uint256 /* minBaseAmountReceived_ */
    ) external override returns (uint256) {
        // TODO implement
        return 0;
    }

    function rebalance() external override returns (uint256) {
        // TODO implement
        return 0;
    }
}
