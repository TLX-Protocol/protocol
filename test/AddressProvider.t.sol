// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {AddressKeys} from "../src/libraries/AddressKeys.sol";

import {Tokens} from "../src/libraries/Tokens.sol";

contract AddressProviderTest is IntegrationTest {
    function testInit() public {
        assertEq(
            address(addressProvider.leveragedTokenFactory()),
            address(leveragedTokenFactory)
        );
        assertEq(address(addressProvider.oracle()), address(oracle));
    }

    function testUpdateAddress() public {
        addressProvider.updateAddress(AddressKeys.ORACLE, Tokens.UNI);
        assertEq(address(addressProvider.oracle()), Tokens.UNI);
    }

    function testQueryAddress() public {
        assertEq(
            addressProvider.addressOf(AddressKeys.ORACLE),
            address(oracle)
        );
    }
}
