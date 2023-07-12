// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {AddressKeys} from "../src/libraries/AddressKeys.sol";

import {ITlxToken} from "../src/interfaces/ITlxToken.sol";

contract TlxTokenTest is IntegrationTest {
    function testInit() public {
        assertEq(tlxToken.name(), "TLX Token");
        assertEq(tlxToken.symbol(), "TLX");
        assertEq(tlxToken.decimals(), 18);
        assertEq(tlxToken.totalSupply(), 0);
        assertEq(tlxToken.balanceOf(address(this)), 0);
    }

    function testMintRevertsForNonAuthorized() public {
        vm.expectRevert(ITlxToken.NotAuthorized.selector);
        tlxToken.mint(address(this), 1);
    }

    function testAirdropMint() public {
        addressProvider.updateAddress(AddressKeys.AIRDROP, address(this));
        tlxToken.mint(address(this), 123e18);
        assertEq(tlxToken.totalSupply(), 123e18);
        assertEq(tlxToken.balanceOf(address(this)), 123e18);
    }

    function testBondingMint() public {
        addressProvider.updateAddress(AddressKeys.BONDING, address(this));
        tlxToken.mint(address(this), 123e18);
        assertEq(tlxToken.totalSupply(), 123e18);
        assertEq(tlxToken.balanceOf(address(this)), 123e18);
    }

    function testTreasuryMint() public {
        addressProvider.updateAddress(AddressKeys.TREASURY, address(this));
        tlxToken.mint(address(this), 123e18);
        assertEq(tlxToken.totalSupply(), 123e18);
        assertEq(tlxToken.balanceOf(address(this)), 123e18);
    }

    function testVestingMint() public {
        addressProvider.updateAddress(AddressKeys.VESTING, address(this));
        tlxToken.mint(address(this), 123e18);
        assertEq(tlxToken.totalSupply(), 123e18);
        assertEq(tlxToken.balanceOf(address(this)), 123e18);
    }
}
