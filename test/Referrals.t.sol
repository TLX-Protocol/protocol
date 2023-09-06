// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Tokens} from "../src/libraries/Tokens.sol";

import {IReferrals} from "../src/interfaces/IReferrals.sol";

contract ReferralsTest is IntegrationTest {
    bytes32 public constant CODE = bytes32(bytes("test"));
    bytes32 public constant ALT = bytes32(bytes("alt"));

    function testInit() public {
        assertEq(referrals.rebate(), 0.5e18);
        assertEq(referrals.earnings(), 0.5e18);

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

    function testSetRebate() public {
        referrals.setRebate(0.3e18);
        assertEq(referrals.rebate(), 0.3e18);
    }

    function testSetRebateRevertsWhenNotChanged() public {
        vm.expectRevert(IReferrals.NotChanged.selector);
        referrals.setRebate(0.5e18);
    }

    function testSetRebateRevertsForInvalidAmount() public {
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setRebate(1.1e18);
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setRebate(0.9e18);
    }

    function testSetEarnings() public {
        referrals.setEarnings(0.3e18);
        assertEq(referrals.earnings(), 0.3e18);
    }

    function testSetEarningsRevertsWhenNotChanged() public {
        vm.expectRevert(IReferrals.NotChanged.selector);
        referrals.setEarnings(0.5e18);
    }

    function testSetEarningsRevertsForInvalidAmount() public {
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setEarnings(1.1e18);
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setEarnings(0.9e18);
    }

    function testUpdateReferralFor() public {
        referrals.register(alice, CODE);

        address positionManager_ = positionManagerFactory.createPositionManager(
            Tokens.UNI
        );
        vm.prank(positionManager_);
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

        _mintTokensFor(Tokens.USDC, address(this), 100e6);
        IERC20(Tokens.USDC).approve(address(referrals), 100e6);
        referrals.takeEarnings(10e6, bob);

        assertEq(IERC20(Tokens.USDC).balanceOf(address(referrals)), 10e6);
        assertEq(referrals.earned(bob), 5e6);
        assertEq(referrals.earned(alice), 5e6);
    }

    function testClaimEarnings() public {
        referrals.register(alice, CODE);

        vm.prank(bob);
        referrals.updateReferral(CODE);

        _mintTokensFor(Tokens.USDC, address(this), 100e6);
        IERC20(Tokens.USDC).approve(address(referrals), 100e6);
        referrals.takeEarnings(10e6, bob);

        vm.prank(alice);
        referrals.claimEarnings();
        assertEq(IERC20(Tokens.USDC).balanceOf(address(referrals)), 5e6);
        assertEq(referrals.earned(bob), 5e6);
        assertEq(referrals.earned(alice), 0);
        assertEq(IERC20(Tokens.USDC).balanceOf(alice), 5e6);
    }
}
