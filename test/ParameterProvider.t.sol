// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {ParameterKeys} from "../src/libraries/ParameterKeys.sol";

import {Tokens} from "../src/libraries/Tokens.sol";
import {Config} from "../src/libraries/Config.sol";

contract ParameterProviderTest is IntegrationTest {
    function testInit() public {
        assertEq(
            parameterProvider.rebalanceThreshold(),
            Config.REBALANCE_THRESHOLD
        );
    }

    function testUpdateParameter() public {
        parameterProvider.updateParameter(
            ParameterKeys.REBALANCE_THRESHOLD,
            0.9e18
        );
        assertEq(parameterProvider.rebalanceThreshold(), 0.9e18);
    }

    function testRevertsForNonOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        parameterProvider.updateParameter(
            ParameterKeys.REBALANCE_THRESHOLD,
            0.9e18
        );
    }

    function testQueryParameter() public {
        assertEq(
            parameterProvider.parameterOf(ParameterKeys.REBALANCE_THRESHOLD),
            Config.REBALANCE_THRESHOLD
        );
    }
}
