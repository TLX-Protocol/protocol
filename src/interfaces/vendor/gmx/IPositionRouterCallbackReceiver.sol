// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPositionRouterCallbackReceiver {
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) external;
}
