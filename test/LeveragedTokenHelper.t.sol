// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Symbols} from "../src/libraries/Symbols.sol";
import {Config} from "../src/libraries/Config.sol";

import {LeveragedTokenHelper} from "../src/helpers/LeveragedTokenHelper.sol";

import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";

contract LeveragedTokenHelperTest is IntegrationTest {
    LeveragedTokenHelper leveragedTokenHelper;

    function setUp() public override {
        super.setUp();
        leveragedTokenHelper = new LeveragedTokenHelper(
            address(addressProvider)
        );
    }

    function testInit() public {
        LeveragedTokenHelper.LeveragedTokenData[]
            memory leveragedTokens = leveragedTokenHelper.leveragedTokenData();
        assertEq(leveragedTokens.length, 0);
    }

    function testQueryDataNoMints() public {
        leveragedTokenFactory.createLeveragedTokens(
            Symbols.ETH,
            2e18,
            Config.REBALANCE_THRESHOLD
        );
        LeveragedTokenHelper.LeveragedTokenData[]
            memory leveragedTokens = leveragedTokenHelper.leveragedTokenData(
                address(this)
            );
        assertEq(leveragedTokens[0].leverage, 0);
    }

    function testQueryData() public {
        leveragedTokenFactory.createLeveragedTokens(
            Symbols.ETH,
            2e18,
            Config.REBALANCE_THRESHOLD
        );
        ILeveragedToken longToken = ILeveragedToken(
            leveragedTokenFactory.allTokens()[0]
        );
        ILeveragedToken shortToken = ILeveragedToken(
            leveragedTokenFactory.allTokens()[1]
        );
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        IERC20(Config.BASE_ASSET).approve(address(longToken), 100e18);
        longToken.mint(100e18, 0);
        _executeOrder(address(longToken));

        LeveragedTokenHelper.LeveragedTokenData[]
            memory leveragedTokens = leveragedTokenHelper.leveragedTokenData();

        assertEq(leveragedTokens.length, 2, "long, length");
        assertEq(leveragedTokens[0].addr, address(longToken), "long, addr");
        assertEq(leveragedTokens[0].userBalance, 0, "long, userBalance");
        assertEq(leveragedTokens[0].symbol, "ETH2L", "long, symbol");
        assertApproxEqRel(
            leveragedTokens[0].totalSupply,
            100e18,
            0.03e18,
            "long, totalSupply"
        );
        assertEq(
            leveragedTokens[0].targetAsset,
            Symbols.ETH,
            "long, targetAsset"
        );
        assertEq(
            leveragedTokens[0].targetLeverage,
            2e18,
            "long, targetLeverage"
        );
        assertTrue(leveragedTokens[0].isLong, "long, isLong");
        assertTrue(leveragedTokens[0].isActive, "long, isActive");
        assertEq(
            leveragedTokens[0].rebalanceThreshold,
            Config.REBALANCE_THRESHOLD,
            "long, rebalanceThreshold"
        );
        assertApproxEqRel(
            leveragedTokens[0].exchangeRate,
            1e18,
            0.05e18,
            "long, exchangeRate"
        );
        assertFalse(leveragedTokens[0].canRebalance, "long, canRebalance");
        assertFalse(
            leveragedTokens[0].hasPendingLeverageUpdate,
            "long, hasPendingLeverageUpdate"
        );
        assertApproxEqRel(
            leveragedTokens[0].leverage,
            2e18,
            0.05e18,
            "long, leverage"
        );
        assertGt(leveragedTokens[0].assetPrice, 1000e18, "long, assetPrice");
        assertLt(leveragedTokens[0].assetPrice, 10000e18, "long, assetPrice");

        assertEq(leveragedTokens[1].addr, address(shortToken), "short, addr");
        assertEq(leveragedTokens[1].userBalance, 0, "short, userBalance");
        assertEq(leveragedTokens[1].symbol, "ETH2S", "short, symbol");
        assertEq(leveragedTokens[1].totalSupply, 0, "short, totalSupply");
        assertEq(
            leveragedTokens[1].targetAsset,
            Symbols.ETH,
            "short, targetAsset"
        );
        assertEq(
            leveragedTokens[1].targetLeverage,
            2e18,
            "short, targetLeverage"
        );
        assertFalse(leveragedTokens[1].isLong, "short, isLong");
        assertTrue(leveragedTokens[1].isActive, "short, isActive");
        assertEq(
            leveragedTokens[1].rebalanceThreshold,
            Config.REBALANCE_THRESHOLD,
            "short, rebalanceThreshold"
        );
        assertApproxEqRel(
            leveragedTokens[1].exchangeRate,
            1e18,
            0.05e18,
            "short, exchangeRate"
        );
        assertFalse(leveragedTokens[1].canRebalance, "short, canRebalance");
        assertFalse(
            leveragedTokens[1].hasPendingLeverageUpdate,
            "short, hasPendingLeverageUpdate"
        );
        assertEq(leveragedTokens[1].leverage, 0, "short, leverage");
        assertGt(leveragedTokens[1].assetPrice, 1000e18, "short, assetPrice");
        assertLt(leveragedTokens[1].assetPrice, 10000e18, "short, assetPrice");
    }
}
