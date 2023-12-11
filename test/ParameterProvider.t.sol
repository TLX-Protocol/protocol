// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {ParameterKeys} from "../src/libraries/ParameterKeys.sol";
import {Tokens} from "../src/libraries/Tokens.sol";
import {Config} from "../src/libraries/Config.sol";
import {Errors} from "../src/libraries/Errors.sol";

import {IParameterProvider} from "../src/interfaces/IParameterProvider.sol";

contract ParameterProviderTest is IntegrationTest {
    function testInit() public {
        assertEq(parameterProvider.streamingFee(), Config.STREAMING_FEE);
    }

    function testUpdateParameter() public {
        parameterProvider.updateParameter(ParameterKeys.STREAMING_FEE, 0.9e18);
        assertEq(parameterProvider.streamingFee(), 0.9e18);
    }

    function testRevertsForNonOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        parameterProvider.updateParameter(ParameterKeys.STREAMING_FEE, 0.9e18);
    }

    function testRevertsForSameAsCurrent() public {
        vm.expectRevert(Errors.SameAsCurrent.selector);
        parameterProvider.updateParameter(
            ParameterKeys.STREAMING_FEE,
            Config.STREAMING_FEE
        );
    }

    function testQueryParameter() public {
        assertEq(
            parameterProvider.parameterOf(ParameterKeys.STREAMING_FEE),
            Config.STREAMING_FEE
        );
    }

    function testParameters() public {
        uint256 oldLength_ = parameterProvider.parameters().length;
        bytes32 newKey = "newKey";
        parameterProvider.updateParameter(newKey, 123);
        assertEq(parameterProvider.parameters().length, oldLength_ + 1);
        assertEq(parameterProvider.parameters()[oldLength_].key, newKey);
        assertEq(parameterProvider.parameters()[oldLength_].value, 123);
    }

    function testRebalanceThreshold() public {
        assertEq(parameterProvider.rebalanceThreshold(address(this)), 0);
        parameterProvider.updateRebalanceThreshold(address(this), 0.5e18);
        assertEq(parameterProvider.rebalanceThreshold(address(this)), 0.5e18);
        vm.expectRevert(Errors.SameAsCurrent.selector);
        parameterProvider.updateRebalanceThreshold(address(this), 0.5e18);
        vm.expectRevert(IParameterProvider.InvalidRebalanceThreshold.selector);
        parameterProvider.updateRebalanceThreshold(address(this), 0.9e18);
        vm.expectRevert(IParameterProvider.InvalidRebalanceThreshold.selector);
        parameterProvider.updateRebalanceThreshold(address(this), 0.001e18);
    }
}
