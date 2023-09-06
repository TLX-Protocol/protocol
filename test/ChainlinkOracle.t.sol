// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Tokens} from "../src/libraries/Tokens.sol";
import {Contracts} from "../src/libraries/Contracts.sol";

import {IChainlinkOracle} from "../src/interfaces/IChainlinkOracle.sol";

contract ChainlinkOracleTest is IntegrationTest {
    function testPriceThroughUsd() public {
        uint256 price_ = chainlinkOracle.getUsdPrice(Tokens.UNI);
        assertGt(price_, 1e18);
        assertLt(price_, 100e18);
    }

    function testPriceThroughEth() public {
        chainlinkOracle.setEthOracle(Tokens.WBTC, Contracts.WBTC_ETH_ORACLE);
        uint256 price_ = chainlinkOracle.getUsdPrice(Tokens.WBTC);
        assertGt(price_, 5000e18);
        assertLt(price_, 100000e18);
    }

    function testUpdateStalePriceDelay() public {
        assertEq(chainlinkOracle.stalePriceDelay(), 1 days);
        chainlinkOracle.setStalePriceDelay(0);
        assertEq(chainlinkOracle.stalePriceDelay(), 0 days);
        vm.expectRevert(IChainlinkOracle.StalePrice.selector);
        chainlinkOracle.getUsdPrice(Tokens.UNI);
    }

    function testPriceLeveragedToken() public {
        positionManagerFactory.createPositionManager(Tokens.UNI);
        leveragedTokenFactory.createLeveragedTokens(Tokens.UNI, 1.23e18);
        uint256 price_ = chainlinkOracle.getUsdPrice(
            leveragedTokenFactory.longTokens(Tokens.UNI)[0]
        );
        assertApproxEqAbs(price_, 2e18, 1e16);
    }
}
