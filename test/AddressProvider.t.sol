// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {AddressKeys} from "../src/libraries/AddressKeys.sol";
import {Tokens} from "../src/libraries/Tokens.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract AddressProviderTest is IntegrationTest {
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

    function testRevertsWhenSameAsCurrent() public {
        vm.expectRevert(Errors.SameAsCurrent.selector);
        addressProvider.updateAddress(AddressKeys.AIRDROP, address(airdrop));
    }

    function testRevertsWhenZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        addressProvider.updateAddress(AddressKeys.AIRDROP, address(0));
    }
}
