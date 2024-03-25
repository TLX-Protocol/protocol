// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Symbols} from "../src/libraries/Symbols.sol";
import {Config} from "../src/libraries/Config.sol";

import {LiquidationPointsClaimer} from "../src/helpers/LiquidationPointsClaimer.sol";

import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";

contract LiquidationPointsClaimerTest is IntegrationTest {
    LiquidationPointsClaimer liquidationPointsClaimer;

    function setUp() public override {
        super.setUp();
        liquidationPointsClaimer = new LiquidationPointsClaimer();
    }

    function testClaim() public {
        assertEq(liquidationPointsClaimer.claimers().length, 0);
        liquidationPointsClaimer.claimLiquidationPoints();
        assertEq(liquidationPointsClaimer.claimers().length, 1);
        assertEq(liquidationPointsClaimer.claimers()[0], address(this));
        vm.prank(alice);
        liquidationPointsClaimer.claimLiquidationPoints();
        assertEq(liquidationPointsClaimer.claimers().length, 2);
        assertEq(liquidationPointsClaimer.claimers()[0], address(this));
        assertEq(liquidationPointsClaimer.claimers()[1], alice);
    }
}
