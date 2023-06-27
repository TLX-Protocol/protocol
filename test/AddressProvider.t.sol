// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {AddressProvider} from "../src/AddressProvider.sol";
import {Tokens} from "../src/libraries/Tokens.sol";

contract AddressProviderTest is Test {
    AddressProvider public addressProvider;

    function setUp() public {
        addressProvider = new AddressProvider(Tokens.UNI);
    }

    function testInit() public {
        assertEq(addressProvider.leveragedTokenFactory(), Tokens.UNI);
    }
}
