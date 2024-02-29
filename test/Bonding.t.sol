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
import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";

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

        vm.expectRevert(Errors.NotLeveragedToken.selector);
        bonding.bond(Tokens.UNI, 1e18, 0);

        vm.mockCall(
            address(leveragedToken),
            abi.encodeWithSelector(ILeveragedToken.isActive.selector),
            abi.encode(false)
        );
        vm.expectRevert(IBonding.InactiveToken.selector);
        bonding.bond(leveragedToken, 1e18, 0);
    }

    function testShouldRevertForNotEnoughTlx() public {
        bonding.launch();

        vm.expectRevert(IBonding.MinTlxNotReached.selector);
        bonding.bond(leveragedToken, 1e18, 1e18);
    }

    function testShouldBondAll() public {
        bonding.launch();

        // Half of a period
        skip(10 days);

        // Expected amount after 10 days
        uint256 expectedTlx_ = 588_038.4e18;

        assertEq(bonding.availableTlx(), expectedTlx_, "availableTlx");

        assertApproxEqAbs(
            bonding.totalTlxBonded(),
            0,
            0.01e18,
            "totalTlxBonded"
        );

        // 588,038 / 15,000 = 39.202533333333335
        uint256 expectedExchangeRate_ = 39.202533333333335e18;

        assertApproxEqRel(
            bonding.exchangeRate(),
            expectedExchangeRate_,
            0.01e18,
            "exchangeRate"
        );

        uint256 amountRequired_ = 15_000e18;
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
            staker.balanceOf(address(this)),
            expectedTlx_,
            0.01e18,
            "staked balance"
        );
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
    }

    function testRevertsForExceedsAvailable() public {
        bonding.launch();

        // Half of a period
        skip(10 days);

        _mintTokensFor(leveragedToken, address(this), 150_000e18);
        IERC20(leveragedToken).approve(address(bonding), 150_000e18);

        vm.expectRevert(IBonding.ExceedsAvailable.selector);
        bonding.bond(leveragedToken, 150_000e18, 0);
    }

    function testShouldBondAllOverLongPeriod() public {
        bonding.launch();

        // One and a half of a period
        skip(30 days);

        // Expected amount we should give out over the first 30 days
        uint256 firstPeriodAmount_ = 1_176_076.8e18;
        uint256 expectedTlx_ = firstPeriodAmount_ +
            firstPeriodAmount_.mul(Config.PERIOD_DECAY_MULTIPLIER) /
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

        // 1,747,649.05 / 15,000 = 116.50993666666668
        uint256 expectedExchangeRate_ = expectedTlx_.div(15_000e18);

        assertApproxEqAbs(
            bonding.exchangeRate(),
            expectedExchangeRate_,
            0.01e18,
            "exchangeRate"
        );

        uint256 amountRequired_ = 15_000e18;
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
            staker.balanceOf(address(this)),
            expectedTlx_,
            0.01e18,
            "staked balance"
        );
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
    }

    function testAvailabilityThreeYears() public {
        bonding.launch();

        // Three years forward
        skip(1095 days);

        // Expected amount after 3 years
        uint256 expectedTlx_ = 33_129_143.3552428e18;

        assertApproxEqRel(
            bonding.availableTlx(),
            expectedTlx_,
            0.001e18,
            "allAvailableTlx"
        );
    }

    function testAllAvailable() public {
        bonding.launch();

        // Go forward 10,000 days
        skip(10000 days);

        // Close to all allocated TLX expected to be available
        assertApproxEqRel(
            bonding.availableTlx(),
            Config.BONDING_AMOUNT,
            0.001e18,
            "allAvailableTlx"
        );
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
