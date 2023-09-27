// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {AddressKeys} from "../src/libraries/AddressKeys.sol";
import {Config} from "../src/libraries/Config.sol";

import {ITlxToken} from "../src/interfaces/ITlxToken.sol";

contract TlxTokenTest is IntegrationTest {
    function testInit() public {
        assertEq(tlx.name(), "TLX DAO Token");
        assertEq(tlx.symbol(), "TLX");
        assertEq(tlx.decimals(), 18);
        assertEq(
            tlx.totalSupply(),
            Config.AIRDROP_AMOUNT +
                Config.TREASURY_AMOUNT +
                Config.BONDING_AMOUNT +
                Config.VESTING_AMOUNT
        );
        assertEq(tlx.balanceOf(address(this)), 0);
        assertEq(tlx.balanceOf(address(treasury)), Config.TREASURY_AMOUNT);
        assertEq(tlx.balanceOf(address(airdrop)), Config.AIRDROP_AMOUNT);
        assertEq(tlx.balanceOf(address(bonding)), Config.BONDING_AMOUNT);
        assertEq(tlx.balanceOf(address(vesting)), Config.VESTING_AMOUNT);
    }
}