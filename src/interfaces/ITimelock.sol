// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ITimelock {
    struct Call {
        address target;
        bytes data;
    }

    struct Proposal {
        uint256 id;
        uint256 ready;
        Call[] calls;
    }

    event ProposalCreated(uint256 indexed id, uint256 ready, Call[] calls);
    event ProposalExecuted(uint256 indexed id);
    event ProposalCancelled(uint256 indexed id);
    event DelaySet(bytes4 indexed selector, uint256 delay);

    error ProposalNotReady(uint256 id);
    error InvalidTarget();
    error ProposalDoesNotExist(uint256 id);

    /**
     * @notice Creates a proposal, containig multiple calls
     * @param calls_ The calls to execute
     * @return id id of the proposal
     */
    function createProposal(Call[] calldata calls_) external returns (uint256);

    /**
     * @notice Executes a proposal
     * @param id The id of the proposal to execute
     */
    function executeProposal(uint256 id) external;

    /**
     * @notice Cancel a call that is ready
     * @param id The id of the call to be cancelled
     */
    function cancelProposal(uint256 id) external;

    /**
     * @notice Set the delay for a function selector
     * @param selector The function selector to set the delay for
     * @param delay The delay to set
     */
    function setDelay(bytes4 selector, uint256 delay) external;

    /**
     * @notice Get all proposals
     * @return proposals All proposals
     */
    function allProposals() external view returns (Proposal[] memory proposals);

    /**
     * @notice Get pending proposals
     * @return proposals pending proposals
     */
    function pendingProposals()
        external
        view
        returns (Proposal[] memory proposals);

    /**
     * @notice Get ready proposals
     * @return proposals Ready proposals
     */
    function readyProposals()
        external
        view
        returns (Proposal[] memory proposals);

    /**
     * @notice Get the delay for a function selector
     * @param selector The function selector to get the delay for
     * @return delay The delay for the function selector
     */
    function delay(bytes4 selector) external view returns (uint256 delay);
}
