// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {DeploymentScript} from "./shared/DeploymentScript.s.sol";

import {ILocker} from "../../src/interfaces/ILocker.sol";

contract FeesDeployment is DeploymentScript {
    function _run() internal override {
        // Getting deployed contracts
        ILocker locker = ILocker(_getDeployedAddress("Locker"));

        // Enable claiming for locker
        locker.enableClaiming();
    }
}
