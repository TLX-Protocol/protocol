// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Errors} from "../src/libraries/Errors.sol";

import {IVesting} from "../src/interfaces/IVesting.sol";

contract Vesting is IntegrationTest {
    function testInit() public {
        assertEq(vesting.vested(alice), 0, "vested");
        assertEq(vesting.vested(bob), 0, "vested");
        assertEq(vesting.claimable(alice), 0, "claimable");
        assertEq(vesting.claimable(bob), 0, "claimable");
        assertEq(vesting.claimed(alice), 0, "claimed");
        assertEq(vesting.claimed(bob), 0, "claimed");
        assertEq(vesting.vesting(alice), 100e18, "vesting");
        assertEq(vesting.vesting(bob), 200e18, "vesting");
        assertEq(vesting.allocated(alice), 100e18, "allocated");
        assertEq(vesting.allocated(bob), 200e18, "allocated");
    }

    function testClaiming() public {
        skip(365 days / 2);
        assertEq(vesting.allocated(alice), 100e18, "allocated");
        assertEq(vesting.allocated(bob), 200e18, "allocated");
        assertEq(vesting.claimable(alice), 50e18, "claimable");
        assertEq(vesting.claimable(bob), 100e18, "claimable");
        assertEq(vesting.claimed(alice), 0, "claimed");
        assertEq(vesting.claimed(bob), 0, "claimed");
        assertEq(tlx.balanceOf(alice), 0, "balance");
        assertEq(tlx.balanceOf(bob), 0, "balance");
        vm.prank(alice);
        vesting.claim();
        assertEq(vesting.allocated(alice), 100e18, "allocated");
        assertEq(vesting.allocated(bob), 200e18, "allocated");
        assertEq(vesting.claimable(alice), 0, "claimable");
        assertEq(vesting.claimable(bob), 100e18, "claimable");
        assertEq(vesting.claimed(alice), 50e18, "claimed");
        assertEq(vesting.claimed(bob), 0, "claimed");
        assertEq(tlx.balanceOf(alice), 50e18, "balance");
        assertEq(tlx.balanceOf(bob), 0, "balance");
        vm.prank(bob);
        vesting.claim();
        assertEq(vesting.allocated(alice), 100e18, "allocated");
        assertEq(vesting.allocated(bob), 200e18, "allocated");
        assertEq(vesting.claimable(alice), 0, "claimable");
        assertEq(vesting.claimable(bob), 0, "claimable");
        assertEq(vesting.claimed(alice), 50e18, "claimed");
        assertEq(vesting.claimed(bob), 100e18, "claimed");
        assertEq(tlx.balanceOf(alice), 50e18, "balance");
        assertEq(tlx.balanceOf(bob), 100e18, "balance");

        skip(365 days);
        assertEq(vesting.allocated(alice), 100e18, "allocated");
        assertEq(vesting.allocated(bob), 200e18, "allocated");
        assertEq(vesting.claimable(alice), 50e18, "claimable");
        assertEq(vesting.claimable(bob), 100e18, "claimable");
        assertEq(vesting.claimed(alice), 50e18, "claimed");
        assertEq(vesting.claimed(bob), 100e18, "claimed");
        assertEq(tlx.balanceOf(alice), 50e18, "balance");
        assertEq(tlx.balanceOf(bob), 100e18, "balance");
        vm.prank(alice);
        vesting.claim();
        assertEq(vesting.allocated(alice), 100e18, "allocated");
        assertEq(vesting.allocated(bob), 200e18, "allocated");
        assertEq(vesting.claimable(alice), 0, "claimable");
        assertEq(vesting.claimable(bob), 100e18, "claimable");
        assertEq(vesting.claimed(alice), 100e18, "claimed");
        assertEq(vesting.claimed(bob), 100e18, "claimed");
        assertEq(tlx.balanceOf(alice), 100e18, "balance");
        assertEq(tlx.balanceOf(bob), 100e18, "balance");
        vm.prank(bob);
        vesting.claim();
        assertEq(vesting.allocated(alice), 100e18, "allocated");
        assertEq(vesting.allocated(bob), 200e18, "allocated");
        assertEq(vesting.claimable(alice), 0, "claimable");
        assertEq(vesting.claimable(bob), 0, "claimable");
        assertEq(vesting.claimed(alice), 100e18, "claimed");
        assertEq(vesting.claimed(bob), 200e18, "claimed");
        assertEq(tlx.balanceOf(alice), 100e18, "balance");
        assertEq(tlx.balanceOf(bob), 200e18, "balance");

        skip(365 days);
        vm.expectRevert(IVesting.NothingToClaim.selector);
        vm.prank(alice);
        vesting.claim();
    }

    function testDelegate() public {
        skip(365 days / 2);

        // Testing can't claim as delegate
        vm.startPrank(bob);
        vm.expectRevert(IVesting.NotAuthorized.selector);
        vesting.claim(alice, bob);
        vm.stopPrank();

        // Adding delegate
        vm.prank(alice);
        vesting.addDelegate(bob);

        // Reverts
        vm.expectRevert(Errors.ZeroAddress.selector);
        vm.prank(alice);
        vesting.addDelegate(address(0));
        vm.expectRevert(Errors.AlreadyExists.selector);
        vm.prank(alice);
        vesting.addDelegate(bob);

        // Testing can claim as delegate
        vm.prank(bob);
        vesting.claim(alice, bob);
        assertEq(tlx.balanceOf(bob), 50e18, "balance");

        // Removing delegate
        vm.prank(alice);
        vesting.removeDelegate(bob);

        // Reverts
        vm.expectRevert(Errors.ZeroAddress.selector);
        vm.prank(alice);
        vesting.removeDelegate(address(0));
        vm.expectRevert(Errors.DoesNotExist.selector);
        vm.prank(alice);
        vesting.removeDelegate(address(7));

        skip(365 days / 2);
        vm.startPrank(bob);
        vm.expectRevert(IVesting.NotAuthorized.selector);
        vesting.claim(alice, bob);
        vm.stopPrank();
    }
}
