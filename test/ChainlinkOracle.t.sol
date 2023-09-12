// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Tokens} from "../src/libraries/Tokens.sol";
import {Contracts} from "../src/libraries/Contracts.sol";

import {Oracle} from "../src/Oracle.sol";

contract OracleTest is IntegrationTest {
    function testPriceThroughUsd() public {
        uint256 price_ = oracle.getUsdPrice(Tokens.UNI);
        assertGt(price_, 1e18);
        assertLt(price_, 100e18);
    }

    function testPriceThroughEth() public {
        oracle.setEthOracle(Tokens.CBETH, Contracts.CBETH_ETH_ORACLE);
        uint256 price_ = oracle.getUsdPrice(Tokens.CBETH);
        assertGt(price_, 500e18);
        assertLt(price_, 10_000e18);
    }

    function testUpdateStalePriceDelay() public {
        assertEq(oracle.stalePriceDelay(), 1 days);
        oracle.setStalePriceDelay(0);
        assertEq(oracle.stalePriceDelay(), 0 days);
        vm.expectRevert(Oracle.StalePrice.selector);
        oracle.getUsdPrice(Tokens.UNI);
    }

    function testPriceLeveragedToken() public {
        positionManagerFactory.createPositionManager(Tokens.UNI);
        leveragedTokenFactory.createLeveragedTokens(Tokens.UNI, 1.23e18);
        uint256 price_ = oracle.getUsdPrice(
            leveragedTokenFactory.longTokens(Tokens.UNI)[0]
        );
        assertApproxEqAbs(price_, 2e18, 1e16);
    }
}
