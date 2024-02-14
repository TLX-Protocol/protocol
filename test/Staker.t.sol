// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IBaseStaker} from "../src/interfaces/IBaseStaker.sol";

import {Config} from "../src/libraries/Config.sol";

import {BaseStakerTest} from "./BaseStaker.t.sol";

contract StakerTest is BaseStakerTest {
    function setUp() public override {
        super.setUp();
        reward = IERC20Metadata(Config.BASE_ASSET);
        rewardDecimals = reward.decimals();
        rewardAmount = 100 * 10 ** rewardDecimals;
        t = staker;
    }

    function testNameAndSymbol() public {
        assertEq(staker.name(), "Staked TLX DAO Token", "name");
        assertEq(staker.symbol(), "stTLX", "symbol");
    }

    function testConfig() public {
        assertEq(t.unstakeDelay(), Config.STAKER_UNSTAKE_DELAY);
        assertEq(t.rewardToken(), Config.BASE_ASSET, "rewardToken");
    }

    function testAccounting() public {
        uint256 tolerance_ = 1 * 10 ** rewardDecimals;

        // A Stakes 100
        _mintTokensFor(address(tlx), accountA, 100e18);
        vm.prank(accountA);
        tlx.approve(address(t), 100e18);
        vm.prank(accountA);
        t.stake(100e18);

        // B Stakes 200
        _mintTokensFor(address(tlx), accountB, 200e18);
        vm.prank(accountB);
        tlx.approve(address(t), 200e18);
        vm.prank(accountB);
        t.stake(200e18);

        // 100 Reward Tokens Donated
        uint256 donateAmountA = 100 * 10 ** rewardDecimals;
        _mintTokensFor(address(reward), address(this), donateAmountA);
        reward.approve(address(t), donateAmountA);
        t.donateRewards(donateAmountA);

        // Check accounting
        assertEq(t.balanceOf(accountA), 100e18, "accountA balance");
        assertEq(t.balanceOf(accountB), 200e18, "accountB balance");
        assertEq(t.totalStaked(), 300e18, "totalStaked");
        assertEq(t.totalPrepared(), 0, "totalPrepared");
        uint256 expectedA = donateAmountA / 3;
        assertApproxEqAbs(t.claimable(accountA), expectedA, tolerance_);
        uint256 expectedB = (donateAmountA * 2) / 3;
        assertApproxEqAbs(t.claimable(accountB), expectedB, tolerance_);

        // A Prepares Unstake
        vm.prank(accountA);
        uint256 id = t.prepareUnstake(100 * 10 ** rewardDecimals);

        // 200 Reward Tokens Donated
        uint256 donateAmountB = 200 * 10 ** rewardDecimals;
        _mintTokensFor(address(reward), address(this), donateAmountB);
        reward.approve(address(t), donateAmountB);
        t.donateRewards(donateAmountB);

        // Check accounting
        assertEq(t.balanceOf(accountA), 100e18, "accountA balance");
        assertEq(t.balanceOf(accountB), 200e18, "accountB balance");
        assertEq(t.totalStaked(), 300e18, "totalStaked");
        assertEq(t.totalPrepared(), 100e18, "totalPrepared");
        expectedA = donateAmountA / 3;
        assertApproxEqAbs(t.claimable(accountA), expectedA, tolerance_);
        expectedB = (donateAmountA * 2) / 3 + donateAmountB;
        assertApproxEqAbs(t.claimable(accountB), expectedB, tolerance_);

        // C Stakes 300
        _mintTokensFor(address(tlx), accountC, 300e18);
        vm.prank(accountC);
        tlx.approve(address(t), 300e18);
        vm.prank(accountC);
        t.stake(300e18);

        // Check accounting
        assertEq(t.balanceOf(accountA), 100e18, "accountA balance");
        assertEq(t.balanceOf(accountB), 200e18, "accountB balance");
        assertEq(t.balanceOf(accountC), 300e18, "accountC balance");
        assertEq(t.totalStaked(), 600e18, "totalStaked");
        assertEq(t.totalPrepared(), 100e18, "totalPrepared");
        expectedA = donateAmountA / 3;
        assertApproxEqAbs(t.claimable(accountA), expectedA, tolerance_);
        expectedB = (donateAmountA * 2) / 3 + donateAmountB;
        assertApproxEqAbs(t.claimable(accountB), expectedB, tolerance_);
        uint256 expectedC = 0;
        assertApproxEqAbs(t.claimable(accountC), expectedC, tolerance_);

        // A Unstakes
        skip(t.unstakeDelay());
        vm.prank(accountA);
        t.unstake(id);

        // 300 Reward Tokens Donated
        uint256 donateAmountC = 300 * 10 ** rewardDecimals;
        _mintTokensFor(address(reward), address(this), donateAmountC);
        reward.approve(address(t), donateAmountC);
        t.donateRewards(donateAmountC);

        // Check accounting
        assertEq(t.balanceOf(accountA), 0, "accountA balance");
        assertEq(t.balanceOf(accountB), 200e18, "accountB balance");
        assertEq(t.balanceOf(accountC), 300e18, "accountC balance");
        assertEq(t.totalStaked(), 500e18, "totalStaked");
        assertEq(t.totalPrepared(), 0, "totalPrepared");
        expectedA = donateAmountA / 3;
        assertApproxEqAbs(t.claimable(accountA), expectedA, tolerance_);
        expectedB =
            (donateAmountA * 2) /
            3 +
            donateAmountB +
            (donateAmountC * 2) /
            5;
        assertApproxEqAbs(t.claimable(accountB), expectedB, tolerance_);
        expectedC = (donateAmountC * 3) / 5;
        assertApproxEqAbs(t.claimable(accountC), expectedC, tolerance_);
    }

    function testDonateRewards() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        _mintTokensFor(address(reward), address(this), rewardAmount);
        tlx.approve(address(t), 100e18);
        t.stake(100e18);
        reward.approve(address(t), rewardAmount);
        t.donateRewards(rewardAmount);
        assertEq(reward.balanceOf(address(this)), 0, "reward balance");
        assertEq(reward.balanceOf(address(staker)), rewardAmount);
        assertEq(t.claimable(address(this)), rewardAmount, "claimable");
    }

    function testClaimingDisabled() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        _mintTokensFor(address(reward), address(this), rewardAmount);
        tlx.approve(address(t), 100e18);
        t.stake(100e18);
        reward.approve(address(t), rewardAmount);
        t.donateRewards(rewardAmount);
        uint256 claimable_ = t.claimable(address(this));
        assertEq(claimable_, rewardAmount, "claimable");
        vm.expectRevert(IBaseStaker.ClaimingNotEnabled.selector);
        t.claim();
    }

    function testClaim() public {
        t.enableClaiming();
        _mintTokensFor(address(tlx), address(this), 100e18);
        _mintTokensFor(address(reward), address(this), rewardAmount);
        tlx.approve(address(t), 100e18);
        t.stake(100e18);
        reward.approve(address(t), rewardAmount);
        t.donateRewards(rewardAmount);
        assertEq(reward.balanceOf(address(this)), 0, "reward balance");
        assertEq(reward.balanceOf(address(staker)), rewardAmount);
        uint256 claimable_ = t.claimable(address(this));
        assertEq(claimable_, rewardAmount, "claimable");
        t.claim();
        uint256 claimed_ = reward.balanceOf(address(this));
        assertEq(claimed_, claimable_, "claimed");
        assertEq(claimed_, rewardAmount);
        assertEq(reward.balanceOf(address(staker)), 0);
        assertEq(t.claimable(address(this)), 0, "claimable");
    }
}
