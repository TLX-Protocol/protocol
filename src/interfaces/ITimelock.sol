// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ITimelock {
    struct Call {
        uint64 id;
        uint64 ready;
        uint64 executed;
        uint64 cancelled;
        address target;
        bytes data;
    }

    event CallPrepared(uint64 id, address target, bytes data);
    event CallExecuted(uint64 id, address target, bytes data);
    event CallCancelled(uint64 id, address target, bytes data);
    event DelaySet(bytes4 selector, uint64 delay);

    error CallNotReady(uint64 id);
    error CallAlreadyExecuted(uint64 id);
    error CallAlreadyCancelled(uint64 id);
    error CallFailed(uint64 id, bytes returnData);
    error NotAuthorized();

    /**
     * @notice Prepare a call to be executed after a delay
     * @param target The address of the contract to be called
     * @param data The data to be passed to the contract
     */
    function prepareCall(address target, bytes calldata data) external;

    /**
     * @notice Execute a call that is ready
     * @param id The id of the call to be executed
     */
    function executeCall(uint64 id) external;

    /**
     * @notice Cancel a call that is ready
     * @param id The id of the call to be cancelled
     */
    function cancelCall(uint64 id) external;

    /**
     * @notice Set the delay for a function selector
     * @param selector The function selector to set the delay for
     * @param delay The delay to set
     */
    function setDelay(bytes4 selector, uint64 delay) external;

    /**
     * @notice Get all calls
     * @return calls All calls
     */
    function allCalls() external view returns (Call[] memory calls);

    /**
     * @notice Get pending calls
     * @return calls Pending calls
     */
    function pendingCalls() external view returns (Call[] memory calls);

    /**
     * @notice Get ready calls
     * @return calls Ready calls
     */
    function readyCalls() external view returns (Call[] memory calls);

    /**
     * @notice Get executed calls
     * @return calls Executed calls
     */
    function executedCalls() external view returns (Call[] memory calls);

    /**
     * @notice Get cancelled calls
     * @return calls Cancelled calls
     */
    function cancelledCalls() external view returns (Call[] memory calls);

    /**
     * @notice Get the delay for a function selector
     * @param selector The function selector to get the delay for
     * @return delay The delay for the function selector
     */
    function delay(bytes4 selector) external view returns (uint64 delay);
}
