// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {DeploymentScript} from "./shared/DeploymentScript.s.sol";

import {IStaker} from "../../src/interfaces/IStaker.sol";

contract EnableFeesDeployment is DeploymentScript, Test {
    function _run() internal override {
        // Getting deployed contracts
        IStaker staker = IStaker(_getDeployedAddress("Staker"));

        // Enable claiming for staker
        staker.enableClaiming();
    }

    function testEnableFeesDeployment() public {
        IStaker staker = IStaker(_getDeployedAddress("Staker"));
        assertEq(staker.claimingEnabled(), true, "claimingEnabled");
    }
}
