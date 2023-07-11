// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ITimelock {
    error CallNotReady(uint64 id);
    error CallAlreadyExecuted(uint64 id);
    error CallAlreadyCancelled(uint64 id);
    error CallFailed(uint64 id, bytes returnData);
    error NotAuthorized();

    struct Call {
        uint64 id;
        uint64 ready;
        uint64 executed;
        uint64 cancelled;
        address target;
        bytes data;
    }

    function prepareCall(address target, bytes calldata data) external;

    function executeCall(uint64 id) external;

    function cancelCall(uint64 id) external;

    function setDelay(bytes4 selector, uint64 delay) external;

    function allCalls() external view returns (Call[] memory);

    function pendingCalls() external view returns (Call[] memory);

    function readyCalls() external view returns (Call[] memory);

    function executedCalls() external view returns (Call[] memory);

    function cancelledCalls() external view returns (Call[] memory);

    function delay(bytes4 selector) external view returns (uint64 delay);
}
