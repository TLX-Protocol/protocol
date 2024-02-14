// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Config} from "../src/libraries/Config.sol";

import {BaseStakerTest} from "./BaseStaker.t.sol";

contract GenesisLockerTest is BaseStakerTest {
    function setUp() public override {
        super.setUp();
        reward = tlx;
        rewardDecimals = reward.decimals();
        rewardAmount = 100 * 10 ** rewardDecimals;
        t = genesisLocker;
    }

    function testConfig() public {
        assertEq(
            t.unstakeDelay(),
            Config.GENESIS_LOCKER_UNLOCK_DELAY,
            "unstake delay"
        );
        assertEq(
            genesisLocker.streamingPeriod(),
            Config.GENESIS_LOCKER_STREAMING_PERIOD,
            "streaming period"
        );
        assertEq(genesisLocker.rewardToken(), address(tlx), "reward token");
    }

    function testDonateRewards() public {
        assertEq(genesisLocker.donatedAmount(), 0, "donated amount");
        assertEq(genesisLocker.donatedAt(), 0, "donated at");

        _donateRewardAmount();

        assertEq(genesisLocker.donatedAmount(), rewardAmount, "donated amount");
        assertEq(genesisLocker.donatedAt(), block.timestamp, "donated at");
    }

    function testAmountStreamed() public {
        assertEq(genesisLocker.amountStreamed(), 0);

        _donateRewardAmount();

        assertEq(genesisLocker.amountStreamed(), 0, "t = 0");
        skip(Config.GENESIS_LOCKER_STREAMING_PERIOD / 4);
        assertEq(genesisLocker.amountStreamed(), rewardAmount / 4, "t = 1/4");

        skip(Config.GENESIS_LOCKER_STREAMING_PERIOD / 4);
        assertEq(genesisLocker.amountStreamed(), rewardAmount / 2, "t = 1/2");

        skip(Config.GENESIS_LOCKER_STREAMING_PERIOD);
        assertEq(genesisLocker.amountStreamed(), rewardAmount, "t > 1");
    }

    function testNoStakerAtBeginning() public {
        t.enableClaiming();
        _donateRewardAmount();

        skip(Config.GENESIS_LOCKER_STREAMING_PERIOD / 4);

        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(t), 100e18);
        t.stakeFor(100e18, bob);

        vm.prank(bob);
        t.claim();

        assertEq(tlx.balanceOf(bob), rewardAmount / 4, "balance");
        assertEq(
            genesisLocker.amountAccounted(),
            rewardAmount / 4,
            "amountAccounted"
        );
    }

    function testManyStakers() public {
        t.enableClaiming();
        _donateRewardAmount();

        _mintTokensFor(address(tlx), address(this), 200e18);
        tlx.approve(address(t), 200e18);

        t.stakeFor(100e18, bob);

        skip(Config.GENESIS_LOCKER_STREAMING_PERIOD / 4);

        t.stakeFor(25e18, alice);

        assertEq(t.claimable(bob), rewardAmount / 4, "claimable bob");
        assertEq(t.claimable(alice), 0, "claimable alice");

        skip(Config.GENESIS_LOCKER_STREAMING_PERIOD / 4);

        assertEq(
            t.claimable(bob),
            rewardAmount / 4 + (rewardAmount * 8) / 40,
            "claimable bob"
        );
        assertEq(
            t.claimable(alice),
            (rewardAmount * 2) / 40,
            "claimable alice"
        );

        skip(Config.GENESIS_LOCKER_STREAMING_PERIOD);

        uint256 expectedBob = rewardAmount / 4 + (3 * (rewardAmount * 8)) / 40;
        uint256 expectedAlice = (3 * (rewardAmount * 2)) / 40;

        assertEq(t.claimable(bob), expectedBob, "claimable bob");
        assertEq(t.claimable(alice), expectedAlice, "claimable alice");

        vm.prank(bob);
        t.claim();
        assertEq(tlx.balanceOf(bob), expectedBob, "balance bob");

        vm.prank(alice);
        t.claim();
        assertEq(tlx.balanceOf(alice), expectedAlice, "balance alice");
    }

    function _donateRewardAmount() internal {
        _mintTokensFor(address(tlx), address(this), rewardAmount);
        tlx.approve(address(genesisLocker), rewardAmount);
        t.donateRewards(rewardAmount);
    }
}
