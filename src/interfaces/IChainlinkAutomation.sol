// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {AutomationCompatibleInterface} from "chainlink/src/v0.8/automation/AutomationCompatible.sol";

interface IChainlinkAutomation is AutomationCompatibleInterface {
    event UpkeepPerformed(address indexed leveragedToken);
    event UpkeepFailed(
        address indexed leveragedToken,
        uint256 nextAttempt,
        uint256 failedCounter
    );
    event FailedCounterReset(address indexed leveragedToken);

    error NoRebalancableTokens();
    error NotReadyForNextAttempt();
    error NotForwarder();

    /**
     * @notice Sets the maximum number of rebalances that can be performed in a single upkeep.
     * @param maxRebalances The new maximum number of rebalances.
     */
    function setMaxRebalances(uint256 maxRebalances) external;

    /**
     * @notice Adds a forwarder address that can call the performUpkeep function.
     * @dev Only callable by the contract owner.
     * @param forwarderAddress The new address of the Chainlink forwarder.
     */
    function addForwarderAddress(address forwarderAddress) external;

    /**
     * @notice Removes a forwarder address that can call the performUpkeep function.
     * @dev Only callable by the contract owner.
     * @param forwarderAddress The address of the Chainlink forwarder to remove.
     */
    function removeForwarderAddress(address forwarderAddress) external;

    /**
     * @notice Resets the failed counter for the given leveraged token.
     * @dev Only callable by the contract owner.
     * @param leveragedToken The leveraged token to reset the failed counter for.
     */
    function resetFailedCounter(address leveragedToken) external;

    /**
     * @notice Returns the addresses of the Chainlink forwarders.
     * @return forwarderAddresses The addresses of the Chainlink forwarders.
     */
    function forwarderAddresses()
        external
        view
        returns (address[] memory forwarderAddresses);

    /**
     * @notice Returns the maximum number of rebalances that can be performed in a single upkeep.
     */
    function maxRebalances() external view returns (uint256);
}
