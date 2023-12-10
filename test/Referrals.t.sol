// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Tokens} from "../src/libraries/Tokens.sol";
import {Symbols} from "../src/libraries/Symbols.sol";
import {Config} from "../src/libraries/Config.sol";

import {IReferrals} from "../src/interfaces/IReferrals.sol";
import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";

contract ReferralsTest is IntegrationTest {
    bytes32 public constant CODE = bytes32(bytes("test"));
    bytes32 public constant ALT = bytes32(bytes("alt"));

    function testInit() public {
        assertEq(referrals.rebatePercent(), 0.5e18);
        assertEq(referrals.rebatePercent(), 0.5e18);

        assertEq(referrals.codeRebate(CODE), 0);
        assertEq(referrals.userRebate(alice), 0);
        assertEq(referrals.userRebate(bob), 0);
        assertEq(referrals.referrer(CODE), address(0));
        assertEq(referrals.code(alice), bytes32(0));
        assertEq(referrals.code(bob), bytes32(0));
        assertEq(referrals.referral(alice), bytes32(0));
        assertEq(referrals.referral(bob), bytes32(0));
        assertEq(referrals.earned(bob), 0);
        assertEq(referrals.earned(alice), 0);
    }

    function testRegister() public {
        referrals.register(alice, CODE);
        assertEq(referrals.codeRebate(CODE), 0.5e18);
        assertEq(referrals.userRebate(alice), 0);
        assertEq(referrals.userRebate(bob), 0);
        assertEq(referrals.referrer(CODE), alice);
        assertEq(referrals.code(alice), CODE);
        assertEq(referrals.code(bob), bytes32(0));
        assertEq(referrals.referral(alice), bytes32(0));
        assertEq(referrals.referral(bob), bytes32(0));
    }

    function testRegisterRevertsForNonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        referrals.register(alice, CODE);
    }

    function testRegisterRevertsForCodeTaken() public {
        referrals.register(alice, CODE);
        vm.expectRevert(IReferrals.CodeTaken.selector);
        referrals.register(bob, CODE);
    }

    function testRegisterRevertsAlreadyRegistered() public {
        referrals.register(alice, CODE);
        vm.expectRevert(IReferrals.AlreadyRegistered.selector);
        referrals.register(alice, ALT);
    }

    function testRegisterRevertsWithInvalidCode() public {
        vm.expectRevert(IReferrals.InvalidCode.selector);
        referrals.register(alice, bytes32(0));
    }

    function testUpdateReferral() public {
        referrals.register(alice, CODE);

        vm.prank(bob);
        referrals.updateReferral(CODE);

        assertEq(referrals.codeRebate(CODE), 0.5e18);
        assertEq(referrals.userRebate(alice), 0);
        assertEq(referrals.userRebate(bob), 0.5e18);
        assertEq(referrals.referrer(CODE), alice);
        assertEq(referrals.code(alice), CODE);
        assertEq(referrals.code(bob), bytes32(0));
        assertEq(referrals.referral(alice), bytes32(0));
        assertEq(referrals.referral(bob), CODE);
    }

    function testUpdateReferralRevertsForSameCode() public {
        referrals.register(alice, CODE);

        vm.prank(bob);
        referrals.updateReferral(CODE);

        vm.expectRevert(IReferrals.SameCode.selector);
        vm.prank(bob);
        referrals.updateReferral(CODE);
    }

    function testUpdateReferralRevertsForInvalidCode() public {
        vm.expectRevert(IReferrals.InvalidCode.selector);
        vm.prank(bob);
        referrals.updateReferral(CODE);
    }

    function testSetRebatePercent() public {
        referrals.setRebatePercent(0.3e18);
        assertEq(referrals.rebatePercent(), 0.3e18);
    }

    function testSetRebatePercentRevertsWhenNotChanged() public {
        vm.expectRevert(IReferrals.NotChanged.selector);
        referrals.setRebatePercent(0.5e18);
    }

    function testSetRebatePercentRevertsForInvalidAmount() public {
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setRebatePercent(1.1e18);
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setRebatePercent(0.9e18);
    }

    function testSetEarningsPercent() public {
        referrals.setEarningsPercent(0.3e18);
        assertEq(referrals.earningsPercent(), 0.3e18);
    }

    function testSetEarningsPercentRevertsWhenNotChanged() public {
        vm.expectRevert(IReferrals.NotChanged.selector);
        referrals.setEarningsPercent(0.5e18);
    }

    function testSetEarningsRevertsForInvalidAmount() public {
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setEarningsPercent(1.1e18);
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setEarningsPercent(0.9e18);
    }

    function testUpdateReferralFor() public {
        referrals.register(alice, CODE);

        leveragedTokenFactory.createLeveragedTokens(
            Symbols.UNI,
            2.12e18,
            Config.REBALANCE_THRESHOLD
        );
        vm.prank(
            address(
                ILeveragedToken(
                    leveragedTokenFactory.longTokens(Symbols.UNI)[0]
                ).positionManager()
            )
        );
        referrals.updateReferralFor(bob, CODE);

        assertEq(referrals.codeRebate(CODE), 0.5e18);
        assertEq(referrals.userRebate(alice), 0);
        assertEq(referrals.userRebate(bob), 0.5e18);
        assertEq(referrals.referrer(CODE), alice);
        assertEq(referrals.code(alice), CODE);
        assertEq(referrals.code(bob), bytes32(0));
        assertEq(referrals.referral(alice), bytes32(0));
        assertEq(referrals.referral(bob), CODE);
    }

    function testUpdateReferralForRevertsForNonPositionManager() public {
        vm.expectRevert(IReferrals.NotPositionManager.selector);
        vm.prank(alice);
        referrals.updateReferralFor(bob, CODE);
    }

    function testTakeEarnings() public {
        referrals.register(alice, CODE);

        vm.prank(bob);
        referrals.updateReferral(CODE);

        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        IERC20(Tokens.SUSD).approve(address(referrals), 100e18);
        referrals.takeEarnings(10e18, bob);

        assertEq(IERC20(Tokens.SUSD).balanceOf(address(referrals)), 10e18);
        assertEq(referrals.earned(bob), 5e18);
        assertEq(referrals.earned(alice), 5e18);
    }

    function testClaimEarnings() public {
        referrals.register(alice, CODE);

        vm.prank(bob);
        referrals.updateReferral(CODE);

        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        IERC20(Tokens.SUSD).approve(address(referrals), 100e18);
        referrals.takeEarnings(10e18, bob);

        vm.prank(alice);
        referrals.claimEarnings();
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(referrals)), 5e18);
        assertEq(referrals.earned(bob), 5e18);
        assertEq(referrals.earned(alice), 0);
        assertEq(IERC20(Tokens.SUSD).balanceOf(alice), 5e18);
    }
}
