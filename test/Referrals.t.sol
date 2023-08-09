// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {IReferrals} from "../src/interfaces/IReferrals.sol";

contract ReferralsTest is IntegrationTest {
    bytes32 public constant CODE = bytes32(bytes("test"));
    bytes32 public constant ALT = bytes32(bytes("alt"));

    function testInit() public {
        assertEq(referrals.referralDiscount(), 0.2e18);
        assertEq(referrals.referralEarnings(), 0.2e18);
        assertEq(referrals.partnerDiscount(), 0.5e18);
        assertEq(referrals.partnerEarnings(), 0.5e18);
        assertEq(referrals.discount(CODE), 0);
        assertEq(referrals.discount(alice), 0);
        assertEq(referrals.discount(bob), 0);
        assertEq(referrals.referrer(CODE), address(0));
        assertEq(referrals.code(alice), bytes32(0));
        assertEq(referrals.code(bob), bytes32(0));
        assertEq(referrals.referral(alice), bytes32(0));
        assertEq(referrals.referral(bob), bytes32(0));
        assertEq(referrals.isPartner(alice), false);
        assertEq(referrals.isPartner(bob), false);
    }

    function testRegister() public {
        vm.prank(alice);
        referrals.register(CODE);
        assertEq(referrals.discount(CODE), 0.2e18);
        assertEq(referrals.discount(alice), 0);
        assertEq(referrals.discount(bob), 0);
        assertEq(referrals.referrer(CODE), alice);
        assertEq(referrals.code(alice), CODE);
        assertEq(referrals.code(bob), bytes32(0));
        assertEq(referrals.referral(alice), bytes32(0));
        assertEq(referrals.referral(bob), bytes32(0));
        assertEq(referrals.isPartner(alice), false);
        assertEq(referrals.isPartner(bob), false);
    }

    function testRegisterRevertsForCodeTaken() public {
        vm.prank(alice);
        referrals.register(CODE);
        vm.expectRevert(IReferrals.CodeTaken.selector);
        vm.prank(bob);
        referrals.register(CODE);
    }

    function testRegisterRevertsAlreadyRegistered() public {
        vm.prank(alice);
        referrals.register(CODE);
        vm.expectRevert(IReferrals.AlreadyRegistered.selector);
        vm.prank(alice);
        referrals.register(ALT);
    }

    function testRegisterRevertsWithInvalidCode() public {
        vm.prank(alice);
        vm.expectRevert(IReferrals.InvalidCode.selector);
        referrals.register(bytes32(0));
    }

    function testUpdateReferral() public {
        vm.prank(alice);
        referrals.register(CODE);

        vm.prank(bob);
        referrals.updateReferral(CODE);

        assertEq(referrals.discount(CODE), 0.2e18);
        assertEq(referrals.discount(alice), 0);
        assertEq(referrals.discount(bob), 0.2e18);
        assertEq(referrals.referrer(CODE), alice);
        assertEq(referrals.code(alice), CODE);
        assertEq(referrals.code(bob), bytes32(0));
        assertEq(referrals.referral(alice), bytes32(0));
        assertEq(referrals.referral(bob), CODE);
        assertEq(referrals.isPartner(alice), false);
        assertEq(referrals.isPartner(bob), false);
    }

    function testUpdateReferralRevertsForSameCode() public {
        vm.prank(alice);
        referrals.register(CODE);

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

    function testSetPartner() public {
        vm.prank(alice);
        referrals.register(CODE);

        vm.prank(bob);
        referrals.updateReferral(CODE);
        referrals.setPartner(alice, true);

        assertEq(referrals.discount(CODE), 0.5e18);
        assertEq(referrals.discount(alice), 0);
        assertEq(referrals.discount(bob), 0.5e18);
        assertEq(referrals.referrer(CODE), alice);
        assertEq(referrals.code(alice), CODE);
        assertEq(referrals.code(bob), bytes32(0));
        assertEq(referrals.referral(alice), bytes32(0));
        assertEq(referrals.referral(bob), CODE);
        assertEq(referrals.isPartner(alice), true);
        assertEq(referrals.isPartner(bob), false);
    }

    function testSetPartnerRevertsWhenNotChanged() public {
        vm.expectRevert(IReferrals.NotChanged.selector);
        referrals.setPartner(alice, false);
        referrals.setPartner(alice, true);
        vm.expectRevert(IReferrals.NotChanged.selector);
        referrals.setPartner(alice, true);
    }

    function testSetReferralDiscount() public {
        referrals.setReferralDiscount(0.3e18);
        assertEq(referrals.referralDiscount(), 0.3e18);
    }

    function testSetReferralDiscountRevertsWhenNotChanged() public {
        vm.expectRevert(IReferrals.NotChanged.selector);
        referrals.setReferralDiscount(0.2e18);
    }

    function testSetReferralDiscountRevertsForInvalidAmount() public {
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setReferralDiscount(1.1e18);
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setReferralDiscount(0.9e18);
    }

    function testSetReferralEarnings() public {
        referrals.setReferralEarnings(0.3e18);
        assertEq(referrals.referralEarnings(), 0.3e18);
    }

    function testSetReferralEarningsRevertsWhenNotChanged() public {
        vm.expectRevert(IReferrals.NotChanged.selector);
        referrals.setReferralEarnings(0.2e18);
    }

    function testSetReferralEarningsRevertsForInvalidAmount() public {
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setReferralEarnings(1.1e18);
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setReferralEarnings(0.9e18);
    }

    function testSetPartnerDiscount() public {
        referrals.setPartnerDiscount(0.4e18);
        assertEq(referrals.partnerDiscount(), 0.4e18);
    }

    function testSetPartnerDiscountRevertsWhenNotChanged() public {
        vm.expectRevert(IReferrals.NotChanged.selector);
        referrals.setPartnerDiscount(0.5e18);
    }

    function testSetPartnerDiscountRevertsForInvalidAmount() public {
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setPartnerDiscount(1.1e18);
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setPartnerDiscount(0.9e18);
    }

    function testSetPartnerEarnings() public {
        referrals.setPartnerEarnings(0.4e18);
        assertEq(referrals.partnerEarnings(), 0.4e18);
    }

    function testSetPartnerEarningsRevertsWhenNotChanged() public {
        vm.expectRevert(IReferrals.NotChanged.selector);
        referrals.setPartnerEarnings(0.5e18);
    }

    function testSetPartnerEarningsRevertsForInvalidAmount() public {
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setPartnerEarnings(1.1e18);
        vm.expectRevert(IReferrals.InvalidAmount.selector);
        referrals.setPartnerEarnings(0.9e18);
    }
}
