// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {AutomationCompatibleInterface} from "chainlink/src/v0.8/automation/AutomationCompatible.sol";

interface IMetaKeeper is AutomationCompatibleInterface {
    event UpkeepPerformed(uint256 indexed upkeepID);
    event AssetRecovered(
        address indexed asset,
        address indexed receiver,
        uint256 amount
    );

    error NoUpkeepsToTopUp();
    error NotUpkeep();
    error NotForwarder();
    error OutOfFunds();
    error UpkeepHasSufficientFunds();

    /**
     * @notice Sets the maximum number of topups that can be performed in a single upkeep.
     * @param maxTopUps_ The new maximum number of topups.
     */
    function setMaxTopUps(uint256 maxTopUps_) external;

    /**
     * @notice Sets the topup amount to transfer to in an upkeep,
     * @param topUpAmount_ The new topup amount.
     */
    function setTopUpAmount(uint96 topUpAmount_) external;

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
     * @notice Transfers an asset held by the automation contract to another address.
     * @dev Only callable by the contract owner.
     * @param receiver Address to transfer to.
     * @param asset Address of asset to transfer.
     * @param amount Amount to transfer.
     */
    function recoverAsset(
        address receiver,
        address asset,
        uint256 amount
    ) external;

    /**
     * @notice Returns the addresses of the Chainlink forwarders.
     * @return forwarderAddresses The addresses of the Chainlink forwarders.
     */
    function forwarderAddresses()
        external
        view
        returns (address[] memory forwarderAddresses);

    /**
     * @notice Returns the maximum number of topups that can be performed in a single upkeep.
     */
    function maxTopUps() external view returns (uint256);

    /**
     * @notice Returns the topup amount per upkeep.
     */
    function topUpAmount() external view returns (uint96);
}
