// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Symbols} from "../src/libraries/Symbols.sol";
import {Config} from "../src/libraries/Config.sol";

import {ChainlinkAutomation} from "../src/ChainlinkAutomation.sol";

contract ChainlinkAutomationTest is IntegrationTest {
    ChainlinkAutomation internal chainlinkAutomation;

    function setUp() public override {
        super.setUp();
        chainlinkAutomation = new ChainlinkAutomation(
            address(addressProvider),
            Config.MAX_REBALANCES
        );
    }

    function testInit() public {
        (bool upkeepNeeded, bytes memory performData) = chainlinkAutomation
            .checkUpkeep("");
        assertEq(upkeepNeeded, false);
        assertEq(performData.length, 0);
    }
}
