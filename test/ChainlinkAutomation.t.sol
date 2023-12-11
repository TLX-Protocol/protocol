// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Symbols} from "../src/libraries/Symbols.sol";

import {ChainlinkAutomation} from "../src/ChainlinkAutomation.sol";

contract ChainlinkAutomationTest is IntegrationTest {
    ChainlinkAutomation internal chainlinkAutomation;

    function setUp() public {
        chainlinkAutomation = new ChainlinkAutomation(address(addressProvider));
    }

    function testInit() public {
        (bool upkeepNeeded, bytes memory performData) = chainlinkAutomation
            .checkUpkeep("");
        assertEq(upkeepNeeded, false);
        assertEq(performData.length, 0);
    }
}
