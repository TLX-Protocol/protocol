// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Config} from "../src/libraries/Config.sol";
import {Errors} from "../src/libraries/Errors.sol";

import {IBaseStaker} from "../src/interfaces/IBaseStaker.sol";

abstract contract BaseStakerTest is IntegrationTest {
    IERC20Metadata public reward;
    uint8 public rewardDecimals;
    uint256 public rewardAmount;
    IBaseStaker public t;

    address public accountA = makeAddr("accountA");
    address public accountB = makeAddr("accountB");
    address public accountC = makeAddr("accountC");
    address public accountD = makeAddr("accountD");

    function testInit() public {
        assertEq(t.decimals(), 18, "decimals");
        assertEq(t.balanceOf(address(this)), 0, "balanceOf");
        assertEq(t.totalStaked(), 0, "totalStaked");
        assertEq(t.totalPrepared(), 0, "totalPrepared");
        assertEq(t.claimable(address(this)), 0, "claimable");
        assertEq(t.unstakeTime(address(this), 0), 0, "unstakeTime");
        assertEq(t.isUnstaked(address(this), 0), false, "isUnstaked");
    }

    function testStake() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(t), 100e18);
        t.stake(100e18);
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(t.balanceOf(address(this)), 100e18, "staker balance");
        assertEq(t.totalStaked(), 100e18, "totalStaked");
        assertEq(t.totalPrepared(), 0, "totalPrepared");
        assertEq(t.claimable(address(this)), 0, "claimable");
        assertEq(t.unstakeTime(address(this), 0), 0, "unstakeTime");
        assertEq(t.isUnstaked(address(this), 0), false, "isUnstaked");
    }

    function testStakeRevertsWithZeroAmount() public {
        vm.expectRevert(IBaseStaker.ZeroAmount.selector);
        t.stake(0);
    }

    function testStakeRevertsWithZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        t.stakeFor(100e18, address(0));
    }

    function testStakeFor() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(t), 100e18);
        t.stakeFor(100e18, bob);
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(t.balanceOf(address(this)), 0, "staker balance");
        assertEq(t.balanceOf(bob), 100e18, "staker balance");
        assertEq(t.totalStaked(), 100e18, "totalStaked");
        assertEq(t.totalPrepared(), 0, "totalPrepared");
        assertEq(t.claimable(address(this)), 0, "claimable");
        assertEq(t.claimable(bob), 0, "claimable");
        assertEq(t.unstakeTime(address(this), 0), 0, "unstakeTime");
        assertEq(t.unstakeTime(bob, 0), 0, "unstakeTime");
        assertEq(t.isUnstaked(address(this), 0), false, "isUnstaked");
        assertEq(t.isUnstaked(bob, 0), false, "isUnstaked");
    }

    function testPrepareUnstake() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(t), 100e18);
        t.stake(100e18);
        uint256 id = t.prepareUnstake(100e18);
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(t.balanceOf(address(this)), 100e18, "staker balance");
        assertEq(t.totalStaked(), 100e18, "totalStaked");
        assertEq(t.totalPrepared(), 100e18, "totalPrepared");
        assertEq(t.claimable(address(this)), 0, "claimable");
        assertEq(
            t.unstakeTime(address(this), id),
            block.timestamp + t.unstakeDelay(),
            "unstakeTime"
        );
        assertEq(t.isUnstaked(address(this), id), false, "isUnstaked");
    }

    function testPrepareUnstakeFailsWithInsufficientBalance() public {
        vm.expectRevert(IBaseStaker.InsufficientBalance.selector);
        t.prepareUnstake(100e18);
    }

    function testUnstakeFailsWithNoUnstakePrepared() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(t), 100e18);
        t.stake(100e18);
        vm.expectRevert(Errors.DoesNotExist.selector);
        t.unstake(1);
    }

    function testUnstakeFailsWithNotUnstaked() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(t), 100e18);
        t.stake(100e18);
        uint256 id = t.prepareUnstake(100e18);
        vm.expectRevert(IBaseStaker.NotUnstaked.selector);
        t.unstake(id);
    }

    function testUnstake() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(t), 100e18);
        t.stake(100e18);
        uint256 id = t.prepareUnstake(100e18);
        assertEq(t.isUnstaked(address(this), id), false, "isUnstaked");
        skip(t.unstakeDelay());
        assertEq(t.isUnstaked(address(this), id), true, "isUnstaked");
        t.unstake(id);
        assertEq(tlx.balanceOf(address(this)), 100e18, "tlx balance");
        assertEq(t.balanceOf(address(this)), 0, "staker balance");
        assertEq(t.totalStaked(), 0, "totalStaked");
        assertEq(t.totalPrepared(), 0, "totalPrepared");
        assertEq(t.claimable(address(this)), 0, "claimable");
        assertEq(t.unstakeTime(address(this), id), 0, "unstakeTime");
    }

    function testUnstakeMultiple() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(t), 100e18);
        t.stake(100e18);
        uint256 id = t.prepareUnstake(10e18);
        assertEq(t.activeBalanceOf(address(this)), 90e18, "activeBalance");
        skip(2 days);
        uint256 id2 = t.prepareUnstake(20e18);
        assertEq(t.activeBalanceOf(address(this)), 70e18, "activeBalance");

        skip(t.unstakeDelay() - 2 days);
        t.unstake(id);

        assertEq(tlx.balanceOf(address(this)), 10e18, "tlx balance");
        assertEq(t.activeBalanceOf(address(this)), 70e18, "activeBalance");
        assertEq(t.balanceOf(address(this)), 90e18, "staker balance");

        vm.expectRevert(IBaseStaker.NotUnstaked.selector);
        t.unstake(id2);
        skip(2 days);

        t.unstake(id2);
        assertEq(tlx.balanceOf(address(this)), 30e18, "tlx balance");
        assertEq(t.activeBalanceOf(address(this)), 70e18, "activeBalance");
        assertEq(t.balanceOf(address(this)), 70e18, "staker balance");
    }

    function testUnstakeFor() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(t), 100e18);
        t.stake(100e18);
        uint256 id = t.prepareUnstake(100e18);
        assertEq(t.isUnstaked(address(this), id), false, "isUnstaked");
        assertEq(t.isUnstaked(bob, id), false, "isUnstaked");
        skip(t.unstakeDelay());
        assertEq(t.isUnstaked(address(this), id), true, "isUnstaked");
        assertEq(t.isUnstaked(bob, id), false, "isUnstaked");
        t.unstakeFor(bob, id);
        assertEq(tlx.balanceOf(bob), 100e18, "tlx balance");
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(t.balanceOf(address(this)), 0, "staker balance");
        assertEq(t.balanceOf(bob), 0, "staker balance");
        assertEq(t.totalStaked(), 0, "totalStaked");
        assertEq(t.totalPrepared(), 0, "totalPrepared");
        assertEq(t.claimable(address(this)), 0, "claimable");
        assertEq(t.claimable(bob), 0, "claimable");
        assertEq(t.unstakeTime(address(this), id), 0, "unstakeTime");
        assertEq(t.unstakeTime(bob, id), 0, "unstakeTime");
    }

    function testRestakeReversWithNoUnstakePrepared() public {
        vm.expectRevert(Errors.DoesNotExist.selector);
        t.restake(0);
    }

    function testRestake() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(t), 100e18);
        t.stake(100e18);
        uint256 id = t.prepareUnstake(100e18);
        skip(t.unstakeDelay() / 2);
        t.restake(id);
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(t.balanceOf(address(this)), 100e18, "staker balance");
        assertEq(t.totalStaked(), 100e18, "totalStaked");
        assertEq(t.totalPrepared(), 0, "totalPrepared");
        assertEq(t.claimable(address(this)), 0, "claimable");
        assertEq(t.unstakeTime(address(this), 0), 0, "unstakeTime");
    }

    function testNonOwnerCantEnableClaiming() public {
        vm.startPrank(alice);
        vm.expectRevert();
        t.enableClaiming();
    }

    function testCantEnableClainmingTwice() public {
        t.enableClaiming();
        vm.expectRevert(IBaseStaker.ClaimingAlreadyEnabled.selector);
        t.enableClaiming();
    }
}
