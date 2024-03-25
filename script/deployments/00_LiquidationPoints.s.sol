// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {DeploymentScript} from "./shared/DeploymentScript.s.sol";

import {LiquidationPointsClaimer} from "../../src/helpers/LiquidationPointsClaimer.sol";

contract LiquidationPointsDeployment is DeploymentScript, Test {
    function _run() internal override {
        // LiquidationPointsClaimer Deployment
        LiquidationPointsClaimer liquidationPointsClaimer = new LiquidationPointsClaimer();
        _deployedAddress(
            "LiquidationPointsClaimer",
            address(liquidationPointsClaimer)
        );
    }
}
