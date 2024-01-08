// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Config} from "../src/libraries/Config.sol";
import {Tokens} from "../src/libraries/Tokens.sol";
import {AddressKeys} from "../src/libraries/AddressKeys.sol";
import {ScaledNumber} from "../src/libraries/ScaledNumber.sol";
import {Symbols} from "../src/libraries/Symbols.sol";
import {Errors} from "../src/libraries/Errors.sol";

import {IBonding} from "../src/interfaces/IBonding.sol";

contract BondingTest is IntegrationTest {
    using ScaledNumber for uint256;

    address public leveragedToken;

    function setUp() public override {
        super.setUp();
        leveragedTokenFactory.createLeveragedTokens(
            Symbols.UNI,
            2.12e18,
            Config.REBALANCE_THRESHOLD
        );
        leveragedToken = leveragedTokenFactory.longTokens(Symbols.UNI)[0];
        _mintTokensFor(leveragedToken, address(this), 100_000e18);
        IERC20(leveragedToken).approve(address(bonding), 100_000e18);

        // Setting up a dummy POL
        addressProvider.updateAddress(AddressKeys.POL, Tokens.UNI);
    }

    function testInit() public {
        assertEq(bonding.totalTlxBonded(), 0, "totalTlxBonded");
        assertEq(bonding.availableTlx(), 0, "availableTlx");
        assertEq(bonding.exchangeRate(), 0, "exchangeRate");
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
    }

    function testLaunchingBonding() public {
        assertEq(bonding.isLive(), false);

        // Testing reverts when not live
        vm.expectRevert(IBonding.BondingNotLive.selector);
        bonding.bond(leveragedToken, 1e18, 0);

        // Testing reverts when making live from non owner
        vm.startPrank(alice);
        vm.expectRevert();
        bonding.launch();
        vm.stopPrank();

        // Test making live
        bonding.launch();
        assertEq(bonding.isLive(), true);

        // Testing can bond
        skip(15 days);
        bonding.bond(leveragedToken, 1e18, 0);
    }

    function testShouldRevertForNonLeveragedToken() public {
        bonding.launch();

        vm.expectRevert(IBonding.NotLeveragedToken.selector);
        bonding.bond(Tokens.UNI, 1e18, 0);
    }

    function testShouldRevertForNotEnoughTlx() public {
        bonding.launch();

        vm.expectRevert(IBonding.MinTlxNotReached.selector);
        bonding.bond(leveragedToken, 1e18, 1e18);
    }

    function testShouldBondAll() public {
        bonding.launch();

        // Half of a period
        skip(15 days);

        // Half of the amount we should give out in the first period
        uint256 expectedTlx_ = 250_000e18 / 2;

        assertApproxEqAbs(
            bonding.availableTlx(),
            expectedTlx_,
            0.01e18,
            "availableTlx"
        );
        assertApproxEqAbs(
            bonding.totalTlxBonded(),
            0,
            0.01e18,
            "totalTlxBonded"
        );

        // 125,000 / 75,000 = 1.6666666667
        uint256 expectedExchangeRate_ = 1.6666666667e18;

        assertApproxEqAbs(
            bonding.exchangeRate(),
            expectedExchangeRate_,
            0.01e18,
            "exchangeRate"
        );

        uint256 amountRequired_ = 75_000e18;
        bonding.bond(
            leveragedToken,
            amountRequired_,
            expectedTlx_.mul(0.98e18)
        );

        assertEq(
            IERC20(leveragedToken).balanceOf(address(this)),
            100_000e18 - amountRequired_,
            "leveragedToken balance"
        );

        assertEq(
            IERC20(leveragedToken).balanceOf(Tokens.UNI),
            amountRequired_,
            "leveragedToken balance"
        );

        assertApproxEqAbs(
            bonding.totalTlxBonded(),
            expectedTlx_,
            0.01e18,
            "totalTlxBonded"
        );
        assertEq(bonding.availableTlx(), 0, "availableTlx");
        assertEq(bonding.exchangeRate(), 0, "exchangeRate");
        assertApproxEqAbs(
            locker.balanceOf(address(this)),
            expectedTlx_,
            0.01e18,
            "locked balance"
        );
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
    }

    function testRevertsForExceedsAvailable() public {
        bonding.launch();

        // Half of a period
        skip(15 days);

        _mintTokensFor(leveragedToken, address(this), 150_000e18);
        IERC20(leveragedToken).approve(address(bonding), 150_000e18);

        vm.expectRevert(IBonding.ExceedsAvailable.selector);
        bonding.bond(leveragedToken, 150_000e18, 0);
    }

    function testShouldBondAllOverLongPeriod() public {
        bonding.launch();

        // Half of a period
        skip(45 days);

        // Half of the amount we should give out in the first period
        uint256 firstMonthAmount_ = 250_000e18;
        uint256 expectedTlx_ = firstMonthAmount_ +
            firstMonthAmount_.mul(Config.PERIOD_DECAY_MULTIPLIER) /
            2;

        assertApproxEqAbs(
            bonding.availableTlx(),
            expectedTlx_,
            0.01e18,
            "availableTlx"
        );
        assertApproxEqAbs(
            bonding.totalTlxBonded(),
            0,
            0.01e18,
            "totalTlxBonded"
        );

        // 125,000 / 75,000 = 1.6666666667
        uint256 expectedExchangeRate_ = expectedTlx_.div(75_000e18);

        assertApproxEqAbs(
            bonding.exchangeRate(),
            expectedExchangeRate_,
            0.01e18,
            "exchangeRate"
        );

        uint256 amountRequired_ = 75_000e18;
        bonding.bond(
            leveragedToken,
            amountRequired_,
            expectedTlx_.mul(0.98e18)
        );

        assertEq(
            IERC20(leveragedToken).balanceOf(address(this)),
            100_000e18 - amountRequired_,
            "leveragedToken balance"
        );

        assertEq(
            IERC20(leveragedToken).balanceOf(Tokens.UNI),
            amountRequired_,
            "leveragedToken balance"
        );

        assertApproxEqAbs(
            bonding.totalTlxBonded(),
            expectedTlx_,
            0.01e18,
            "totalTlxBonded"
        );
        assertEq(bonding.availableTlx(), 0, "availableTlx");
        assertEq(bonding.exchangeRate(), 0, "exchangeRate");
        assertApproxEqAbs(
            locker.balanceOf(address(this)),
            expectedTlx_,
            0.01e18,
            "locked balance"
        );
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
    }

    function testMigration() public {
        uint256 bondingBefore_ = tlx.balanceOf(address(bonding));
        assertGt(bondingBefore_, 0);
        vm.expectRevert(Errors.SameAsCurrent.selector);
        bonding.migrate();
        addressProvider.updateAddress(AddressKeys.BONDING, bob);
        uint256 bobBefore = tlx.balanceOf(bob);
        vm.prank(alice);
        vm.expectRevert();
        bonding.migrate();
        bonding.migrate();
        assertEq(tlx.balanceOf(bob), bobBefore + bondingBefore_);
        assertEq(tlx.balanceOf(address(bonding)), 0);
        vm.expectRevert(IBonding.AlreadyMigrated.selector);
        bonding.migrate();
    }
}
