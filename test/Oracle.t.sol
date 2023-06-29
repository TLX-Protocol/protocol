// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Tokens} from "../src/libraries/Tokens.sol";
import {Contracts} from "../src/libraries/Contracts.sol";

import {IOracle} from "../src/interfaces/IOracle.sol";

contract OracleTest is IntegrationTest {
    function testPriceThroughUsd() public {
        uint256 price_ = oracle.getUsdPrice(Tokens.UNI);
        assertGt(price_, 1e18);
        assertLt(price_, 100e18);
    }

    function testPriceThroughEth() public {
        oracle.setEthOracle(Tokens.WBTC, Contracts.WBTC_ETH_ORACLE);
        uint256 price_ = oracle.getUsdPrice(Tokens.WBTC);
        assertGt(price_, 5000e18);
        assertLt(price_, 100000e18);
    }

    function testUpdateStalePriceDelay() public {
        assertEq(oracle.stalePriceDelay(), 1 days);
        oracle.setStalePriceDelay(0);
        assertEq(oracle.stalePriceDelay(), 0 days);
        vm.expectRevert(IOracle.StalePrice.selector);
        oracle.getUsdPrice(Tokens.UNI);
    }
}
