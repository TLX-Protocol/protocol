// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ITimelock {
    struct Call {
        uint256 id;
        uint256 ready;
        address target;
        bytes data;
    }

    struct Proposal {
        address[] targets;
        bytes[] data;
    }

    event CallPrepared(uint256 id, address target, bytes data);
    event CallExecuted(uint256 id, address target, bytes data);
    event CallCancelled(uint256 id, address target, bytes data);
    event DelaySet(bytes4 selector, uint256 delay);

    error CallNotReady(uint256 id);
    error CallFailed(uint256 id, bytes returnData);
    error NotAuthorized();
    error InvalidTarget();
    error CallDoesNotExist(uint256 id);

    /**
     * @notice Prepare a proposal with multiple calls
     * @param proposal The proposal containing a number of calls
     * @return ids Ids of the prepared calls
     */
    function prepareProposal(
        Proposal calldata proposal
    ) external returns (uint256[] memory);

    /**
     * @notice Execute multiple calls
     * @param ids Teh ids of the calls to execute
     * @return returnData return data from all the executed calls
     */
    function executeMultiple(
        uint256[] calldata ids
    ) external returns (bytes[] memory);

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
    function executeCall(uint256 id) external returns (bytes memory);

    /**
     * @notice Cancel a call that is ready
     * @param id The id of the call to be cancelled
     */
    function cancelCall(uint256 id) external;

    /**
     * @notice Set the delay for a function selector
     * @param selector The function selector to set the delay for
     * @param delay The delay to set
     */
    function setDelay(bytes4 selector, uint256 delay) external;

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
     * @notice Get the delay for a function selector
     * @param selector The function selector to get the delay for
     * @return delay The delay for the function selector
     */
    function delay(bytes4 selector) external view returns (uint256 delay);
}
