// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Tokens} from "../src/libraries/Tokens.sol";

contract AddressProviderTest is IntegrationTest {
    function testInit() public {
        assertEq(
            addressProvider.leveragedTokenFactory(),
            address(leveragedTokenFactory)
        );
        assertEq(addressProvider.oracle(), address(oracle));
    }
}
