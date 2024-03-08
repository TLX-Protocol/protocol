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

    error NoRebalancableTokens();
    error NotReadyForNextAttempt();
    error NotForwarder();

    /**
     * @notice Sets the forwarder address which is who can call the performUpkeep function.
     * @dev Only callable by the contract owner.
     * @param forwarderAddress The new address of the Chainlink forwarder.
     */
    function setForwarderAddress(address forwarderAddress) external;

    /**
     * @notice Resets the failed counter for the given leveraged token.
     * @dev Only callable by the contract owner.
     * @param leveragedToken The leveraged token to reset the failed counter for.
     */
    function resetFailedCounter(address leveragedToken) external;

    /**
     * @notice Returns the address of the Chainlink forwarder.
     * @return forwarderAddress The address of the Chainlink forwarder.
     */
    function forwarderAddress()
        external
        view
        returns (address forwarderAddress);
}
