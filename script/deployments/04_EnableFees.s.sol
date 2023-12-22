// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {DeploymentScript} from "./shared/DeploymentScript.s.sol";

import {ILocker} from "../../src/interfaces/ILocker.sol";

contract EnableFeesDeployment is DeploymentScript, Test {
    function _run() internal override {
        // Getting deployed contracts
        ILocker locker = ILocker(_getDeployedAddress("Locker"));

        // Enable claiming for locker
        locker.enableClaiming();
    }

    function testEnableFeesDeployment() public {
        ILocker locker = ILocker(_getDeployedAddress("Locker"));
        assertEq(locker.claimingEnabled(), true, "claimingEnabled");
    }
}
