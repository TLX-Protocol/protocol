// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {DeploymentScript} from "./shared/DeploymentScript.s.sol";

import {Config} from "../../src/libraries/Config.sol";
import {ChainlinkForwarders} from "../../src/libraries/ChainlinkForwarders.sol";

import {IChainlinkAutomation} from "../../src/interfaces/IChainlinkAutomation.sol";

/*
 * After deploying the `ChainlinkAutomation` contract in the ProtocolDeployment script,
 * We then need to go to the Chainlink website, and create an upkeep for it: https://automation.chain.link/optimism
 * After this is done, we need to copy the `Forwarder address` on their UI,
 * Then paste is as the `CHAINLINK_AUTOMATION_FORWARDER_ADDRESS` in the `Config` file.
 * Then we can run this script to set that as the reciever address of the `ChainlinkAutomation` contract.
 */
contract SetupChainlinkAutomationDeployment is DeploymentScript, Test {
    function _run() internal override {
        // Getting deployed contracts
        IChainlinkAutomation chainlinkAutomation = IChainlinkAutomation(
            _getDeployedAddress("ChainlinkAutomation")
        );

        address[] memory forwarders = ChainlinkForwarders.forwarders();
        for (uint i = 0; i < forwarders.length; i++) {
            chainlinkAutomation.addForwarderAddress(forwarders[i]);
        }
    }

    function testEnableFeesDeployment() public {
        IChainlinkAutomation chainlinkAutomation = IChainlinkAutomation(
            _getDeployedAddress("ChainlinkAutomation")
        );
        address[] memory addresses = chainlinkAutomation.forwarderAddresses();
        assertEq(
            addresses,
            ChainlinkForwarders.forwarders(),
            "ChainlinkAutomation Forwarder Address"
        );
    }
}
