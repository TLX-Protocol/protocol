// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {AddressKeys} from "../src/libraries/AddressKeys.sol";
import {Config} from "../src/libraries/Config.sol";

import {ITlxToken} from "../src/interfaces/ITlxToken.sol";

contract TlxTokenTest is IntegrationTest {
    function testInit() public {
        assertEq(tlx.name(), Config.TOKEN_NAME);
        assertEq(tlx.symbol(), Config.TOKEN_SYMBOL);
        assertEq(tlx.decimals(), 18);
        assertEq(
            tlx.totalSupply(),
            Config.AIRDROP_AMOUNT +
                Config.AMM_AMOUNT +
                Config.BONDING_AMOUNT +
                Config.VESTING_AMOUNT
        );
        assertEq(tlx.balanceOf(address(this)), 0);
        assertEq(tlx.balanceOf(address(airdrop)), Config.AIRDROP_AMOUNT);
        assertEq(tlx.balanceOf(address(bonding)), Config.BONDING_AMOUNT);
        assertEq(tlx.balanceOf(address(vesting)), Config.VESTING_AMOUNT);
    }
}
