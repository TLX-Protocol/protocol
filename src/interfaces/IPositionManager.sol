// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IPositionManager {
    function mintAmountIn(
        address leveragedToken_,
        uint256 baseAmountIn_,
        uint256 minLeveragedTokenAmountOut_
    ) external returns (uint256);

    function mintAmountOut(
        address leveragedToken_,
        uint256 leveragedTokenAmountOut_,
        uint256 maxBaseAmountIn_
    ) external returns (uint256);

    function burn(
        address leveragedToken_,
        uint256 leveragedTokenAmount_,
        uint256 minBaseAmountReceived_
    ) external returns (uint256);

    function rebalance() external returns (uint256);

    function baseAsset() external view returns (address);

    function targetAsset() external view returns (address);
}
