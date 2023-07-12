// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {AddressKeys} from "../src/libraries/AddressKeys.sol";

import {ITlxToken} from "../src/interfaces/ITlxToken.sol";

contract TlxTokenTest is IntegrationTest {
    function testInit() public {
        assertEq(tlx.name(), "TLX Token");
        assertEq(tlx.symbol(), "TLX");
        assertEq(tlx.decimals(), 18);
        assertEq(tlx.totalSupply(), 0);
        assertEq(tlx.balanceOf(address(this)), 0);
    }

    function testMintRevertsForNonAuthorized() public {
        vm.expectRevert(ITlxToken.NotAuthorized.selector);
        tlx.mint(address(this), 1);
    }

    function testAirdropMint() public {
        addressProvider.updateAddress(AddressKeys.AIRDROP, address(this));
        tlx.mint(address(this), 123e18);
        assertEq(tlx.totalSupply(), 123e18);
        assertEq(tlx.balanceOf(address(this)), 123e18);
    }

    function testBondingMint() public {
        addressProvider.updateAddress(AddressKeys.BONDING, address(this));
        tlx.mint(address(this), 123e18);
        assertEq(tlx.totalSupply(), 123e18);
        assertEq(tlx.balanceOf(address(this)), 123e18);
    }

    function testTreasuryMint() public {
        addressProvider.updateAddress(AddressKeys.TREASURY, address(this));
        tlx.mint(address(this), 123e18);
        assertEq(tlx.totalSupply(), 123e18);
        assertEq(tlx.balanceOf(address(this)), 123e18);
    }

    function testVestingMint() public {
        addressProvider.updateAddress(AddressKeys.VESTING, address(this));
        tlx.mint(address(this), 123e18);
        assertEq(tlx.totalSupply(), 123e18);
        assertEq(tlx.balanceOf(address(this)), 123e18);
    }
}
