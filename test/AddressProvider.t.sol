// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Test.sol";
import {IntegrationTest} from "./shared/IntegrationTest.sol";
import {Expectations} from "./shared/Expectations.sol";

import {AddressKeys} from "../src/libraries/AddressKeys.sol";
import {IAddressProvider} from "../src/interfaces/IAddressProvider.sol";

import {Tokens} from "../src/libraries/Tokens.sol";

contract AddressProviderTest is IntegrationTest {
    using Expectations for Vm;

    function testInit() public {
        assertEq(
            address(addressProvider.leveragedTokenFactory()),
            address(leveragedTokenFactory)
        );
    }

    function testUpdateAddress() public {
        addressProvider.updateAddress(AddressKeys.REFERRALS, Tokens.UNI);
        assertEq(address(addressProvider.referrals()), Tokens.UNI);
    }

    function testQueryAddress() public {
        assertEq(
            addressProvider.addressOf(AddressKeys.AIRDROP),
            address(airdrop)
        );
    }

    function testFreezeAddress() public {
        addressProvider.freezeAddress(AddressKeys.REFERRALS);
        assertTrue(addressProvider.isAddressFrozen(AddressKeys.REFERRALS));

        vm.expectRevertWith(IAddressProvider.AddressIsFrozen.selector, AddressKeys.REFERRALS);
        addressProvider.updateAddress(AddressKeys.REFERRALS, Tokens.UNI);

        vm.expectRevertWith(IAddressProvider.AddressIsFrozen.selector, AddressKeys.REFERRALS);
        addressProvider.freezeAddress(AddressKeys.REFERRALS);
    }
}
