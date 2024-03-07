// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Config} from "../src/libraries/Config.sol";
import {Errors} from "../src/libraries/Errors.sol";

import {IGenesisLocker} from "../src/interfaces/IGenesisLocker.sol";
import {IRewardsStreaming} from "../src/interfaces/IRewardsStreaming.sol";

contract GenesisLockerTest is IntegrationTest {
    IERC20Metadata public reward;
    uint8 public rewardDecimals;
    uint256 public rewardAmount;

    function setUp() public override {
        super.setUp();
        reward = tlx;
        rewardDecimals = reward.decimals();
        rewardAmount = Config.STREAMED_AIRDROP_AMOUNT;
    }

    function testConfig() public {
        assertEq(
            genesisLocker.lockTime(),
            Config.GENESIS_LOCKER_LOCK_TIME,
            "lock time"
        );
        assertEq(genesisLocker.rewardToken(), address(tlx), "reward token");
        assertEq(genesisLocker.decimals(), 18, "decimals");
    }

    function testDonateRewards() public {
        assertEq(genesisLocker.totalRewards(), rewardAmount, "donated amount");
        assertEq(
            genesisLocker.rewardsStartTime(),
            block.timestamp,
            "donated at"
        );

        vm.expectRevert(Errors.NotAuthorized.selector);
        genesisLocker.donateRewards(100e18);

        vm.expectRevert(IRewardsStreaming.ZeroAmount.selector);
        vm.prank(address(tlx));
        genesisLocker.donateRewards(0);

        vm.expectRevert(IGenesisLocker.RewardsAlreadyDonated.selector);
        vm.prank(address(tlx));
        genesisLocker.donateRewards(1);
    }

    function testLock() public {
        _mintTokensFor(address(tlx), bob, 200e18);
        vm.startPrank(bob);
        tlx.approve(address(genesisLocker), 200e18);
        genesisLocker.lock(100e18);
        vm.stopPrank();

        assertEq(
            genesisLocker.unlockTime(bob),
            block.timestamp + Config.GENESIS_LOCKER_LOCK_TIME,
            "unlock time"
        );
        assertEq(genesisLocker.balanceOf(bob), 100e18);

        skip(Config.GENESIS_LOCKER_LOCK_TIME);
        vm.prank(bob);
        vm.expectRevert(IGenesisLocker.AlreadyShutdown.selector);
        genesisLocker.lock(100e18);
    }

    function testMigrateFor() public {
        _mintTokensFor(address(tlx), bob, 100e18);
        vm.startPrank(bob);
        tlx.approve(address(genesisLocker), 100e18);
        genesisLocker.lock(100e18);

        skip(Config.GENESIS_LOCKER_LOCK_TIME - 1);

        vm.expectRevert(IGenesisLocker.NotUnlocked.selector);
        genesisLocker.migrateFor(alice);

        skip(1);

        genesisLocker.migrateFor(alice);
        assertEq(genesisLocker.balanceOf(bob), 0, "balance bob");
        assertEq(genesisLocker.balanceOf(alice), 0, "balance alice");
        assertEq(staker.balanceOf(bob), 0, "staker balance bob");
        assertEq(staker.balanceOf(alice), 100e18, "staker balance alice");

        vm.stopPrank();
    }

    function testAmountStreamed() public {
        assertEq(genesisLocker.amountStreamed(), 0);

        assertEq(genesisLocker.amountStreamed(), 0, "t = 0");
        skip(Config.GENESIS_LOCKER_LOCK_TIME / 4);
        assertEq(genesisLocker.amountStreamed(), rewardAmount / 4, "t = 1/4");

        skip(Config.GENESIS_LOCKER_LOCK_TIME / 4);
        assertEq(genesisLocker.amountStreamed(), rewardAmount / 2, "t = 1/2");

        skip(Config.GENESIS_LOCKER_LOCK_TIME);
        assertEq(genesisLocker.amountStreamed(), rewardAmount, "t > 1");
    }

    function testNoStakerAtBeginning() public {
        skip(Config.GENESIS_LOCKER_LOCK_TIME / 4);
        _mintTokensFor(address(tlx), bob, 100e18);

        vm.startPrank(bob);
        tlx.approve(address(genesisLocker), 100e18);
        genesisLocker.lock(100e18);

        genesisLocker.claim();

        assertEq(tlx.balanceOf(bob), rewardAmount / 4, "balance");
    }

    function testClaimWithNoAssets() public {
        skip(Config.GENESIS_LOCKER_LOCK_TIME / 4);
        genesisLocker.claim();
    }

    function testManyStakers() public {
        _mintTokensFor(address(tlx), bob, 100e18);
        _mintTokensFor(address(tlx), alice, 25e18);

        vm.startPrank(bob);
        tlx.approve(address(genesisLocker), 100e18);
        genesisLocker.lock(100e18);
        vm.stopPrank();

        skip(Config.GENESIS_LOCKER_LOCK_TIME / 4);

        vm.startPrank(alice);
        tlx.approve(address(genesisLocker), 25e18);
        genesisLocker.lock(25e18);
        vm.stopPrank();

        assertEq(
            genesisLocker.claimable(bob),
            rewardAmount / 4,
            "claimable bob"
        );
        assertEq(genesisLocker.claimable(alice), 0, "claimable alice");

        skip(Config.GENESIS_LOCKER_LOCK_TIME / 4);

        assertEq(
            genesisLocker.claimable(bob),
            rewardAmount / 4 + (rewardAmount * 8) / 40,
            "claimable bob"
        );
        assertEq(
            genesisLocker.claimable(alice),
            (rewardAmount * 2) / 40,
            "claimable alice"
        );

        skip(Config.GENESIS_LOCKER_LOCK_TIME);

        uint256 expectedBob = rewardAmount / 4 + (3 * (rewardAmount * 8)) / 40;
        uint256 expectedAlice = (3 * (rewardAmount * 2)) / 40;

        assertEq(genesisLocker.claimable(bob), expectedBob, "claimable bob");
        assertEq(
            genesisLocker.claimable(alice),
            expectedAlice,
            "claimable alice"
        );

        vm.prank(bob);
        genesisLocker.claim();
        assertEq(tlx.balanceOf(bob), expectedBob, "balance bob");

        vm.prank(alice);
        genesisLocker.claim();
        assertEq(tlx.balanceOf(alice), expectedAlice, "balance alice");
    }

    function testShutdown() public {
        _mintTokensFor(address(tlx), bob, 100e18);

        vm.startPrank(bob);
        tlx.approve(address(genesisLocker), 200e18);
        genesisLocker.lock(100e18);
        vm.stopPrank();

        skip(Config.GENESIS_LOCKER_LOCK_TIME / 4);

        genesisLocker.shutdown();

        assertTrue(genesisLocker.isShutdown(), "is shutdown");

        assertEq(
            tlx.balanceOf(treasury),
            (rewardAmount * 3) / 4,
            "balance treasury"
        );

        assertEq(
            genesisLocker.claimable(bob),
            rewardAmount / 4,
            "claimable bob"
        );
        vm.prank(bob);
        genesisLocker.migrate();
        assertEq(staker.balanceOf(bob), 100e18, "staker balance bob");
        vm.prank(bob);
        genesisLocker.claim();
        assertEq(tlx.balanceOf(bob), rewardAmount / 4, "balance bob");

        assertEq(tlx.balanceOf(address(genesisLocker)), 0, "balance locker");

        _mintTokensFor(address(tlx), bob, 100e18);
        vm.prank(bob);
        vm.expectRevert(IGenesisLocker.AlreadyShutdown.selector);
        genesisLocker.lock(100e18);
    }
}
