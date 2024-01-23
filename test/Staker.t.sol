// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Config} from "../src/libraries/Config.sol";
import {Errors} from "../src/libraries/Errors.sol";

import {IStaker} from "../src/interfaces/IStaker.sol";

contract StakerTest is IntegrationTest {
    IERC20Metadata public reward;
    uint8 public rewardDecimals;
    uint256 public rewardAmount;

    address public accountA = makeAddr("accountA");
    address public accountB = makeAddr("accountB");
    address public accountC = makeAddr("accountC");
    address public accountD = makeAddr("accountD");

    function setUp() public override {
        super.setUp();
        reward = IERC20Metadata(Config.BASE_ASSET);
        rewardDecimals = reward.decimals();
        rewardAmount = 100 * 10 ** rewardDecimals;
    }

    function testInit() public {
        assertEq(staker.name(), "Staked TLX DAO Token", "name");
        assertEq(staker.symbol(), "stTLX", "symbol");
        assertEq(staker.decimals(), 18, "decimals");
        assertEq(staker.balanceOf(address(this)), 0, "balanceOf");
        assertEq(staker.totalStaked(), 0, "totalStaked");
        assertEq(staker.totalPrepared(), 0, "totalPrepared");
        assertEq(staker.claimable(address(this)), 0, "claimable");
        assertEq(staker.unstakeTime(address(this)), 0, "unstakeTime");
        assertEq(staker.isUnstaked(address(this)), false, "isUnstaked");
        assertEq(staker.unstakeDelay(), Config.STAKER_UNSTAKE_DELAY);
        assertEq(staker.rewardToken(), Config.BASE_ASSET, "rewardToken");
    }

    function testStake() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(staker), 100e18);
        staker.stake(100e18);
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(staker.balanceOf(address(this)), 100e18, "staker balance");
        assertEq(staker.totalStaked(), 100e18, "totalStaked");
        assertEq(staker.totalPrepared(), 0, "totalPrepared");
        assertEq(staker.claimable(address(this)), 0, "claimable");
        assertEq(staker.unstakeTime(address(this)), 0, "unstakeTime");
        assertEq(staker.isUnstaked(address(this)), false, "isUnstaked");
    }

    function testStakeRevertsWithZeroAmount() public {
        vm.expectRevert(IStaker.ZeroAmount.selector);
        staker.stake(0);
    }

    function testStakeRevertsWithZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        staker.stakeFor(100e18, address(0));
    }

    function testStakeFor() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(staker), 100e18);
        staker.stakeFor(100e18, bob);
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(staker.balanceOf(address(this)), 0, "staker balance");
        assertEq(staker.balanceOf(bob), 100e18, "staker balance");
        assertEq(staker.totalStaked(), 100e18, "totalStaked");
        assertEq(staker.totalPrepared(), 0, "totalPrepared");
        assertEq(staker.claimable(address(this)), 0, "claimable");
        assertEq(staker.claimable(bob), 0, "claimable");
        assertEq(staker.unstakeTime(address(this)), 0, "unstakeTime");
        assertEq(staker.unstakeTime(bob), 0, "unstakeTime");
        assertEq(staker.isUnstaked(address(this)), false, "isUnstaked");
        assertEq(staker.isUnstaked(bob), false, "isUnstaked");
    }

    function testPrepareUnstake() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(staker), 100e18);
        staker.stake(100e18);
        staker.prepareUnstake();
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(staker.balanceOf(address(this)), 100e18, "staker balance");
        assertEq(staker.totalStaked(), 100e18, "totalStaked");
        assertEq(staker.totalPrepared(), 100e18, "totalPrepared");
        assertEq(staker.claimable(address(this)), 0, "claimable");
        assertEq(
            staker.unstakeTime(address(this)),
            block.timestamp + Config.STAKER_UNSTAKE_DELAY,
            "unstakeTime"
        );
        assertEq(staker.isUnstaked(address(this)), false, "isUnstaked");
    }

    function testStakeFailsWhenUnstakePrepared() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(staker), 100e18);
        staker.stake(50e18);
        staker.prepareUnstake();
        vm.expectRevert(IStaker.UnstakePrepared.selector);
        staker.stake(50e18);
    }

    function testUnstakeFailsWithZeroBalance() public {
        vm.expectRevert(IStaker.ZeroBalance.selector);
        staker.unstake();
    }

    function testUnstakeFailsWithNoUnstakePrepared() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(staker), 100e18);
        staker.stake(100e18);
        vm.expectRevert(IStaker.NoUnstakePrepared.selector);
        staker.unstake();
    }

    function testUnstakeFailsWithNotUnstaked() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(staker), 100e18);
        staker.stake(100e18);
        staker.prepareUnstake();
        vm.expectRevert(IStaker.NotUnstaked.selector);
        staker.unstake();
    }

    function testUnstake() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(staker), 100e18);
        staker.stake(100e18);
        staker.prepareUnstake();
        assertEq(staker.isUnstaked(address(this)), false, "isUnstaked");
        skip(Config.STAKER_UNSTAKE_DELAY);
        assertEq(staker.isUnstaked(address(this)), true, "isUnstaked");
        staker.unstake();
        assertEq(tlx.balanceOf(address(this)), 100e18, "tlx balance");
        assertEq(staker.balanceOf(address(this)), 0, "staker balance");
        assertEq(staker.totalStaked(), 0, "totalStaked");
        assertEq(staker.totalPrepared(), 0, "totalPrepared");
        assertEq(staker.claimable(address(this)), 0, "claimable");
        assertEq(staker.unstakeTime(address(this)), 0, "unstakeTime");
    }

    function testUnstakeFor() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(staker), 100e18);
        staker.stake(100e18);
        staker.prepareUnstake();
        assertEq(staker.isUnstaked(address(this)), false, "isUnstaked");
        assertEq(staker.isUnstaked(bob), false, "isUnstaked");
        skip(Config.STAKER_UNSTAKE_DELAY);
        assertEq(staker.isUnstaked(address(this)), true, "isUnstaked");
        assertEq(staker.isUnstaked(bob), false, "isUnstaked");
        staker.unstakeFor(bob);
        assertEq(tlx.balanceOf(bob), 100e18, "tlx balance");
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(staker.balanceOf(address(this)), 0, "staker balance");
        assertEq(staker.balanceOf(bob), 0, "staker balance");
        assertEq(staker.totalStaked(), 0, "totalStaked");
        assertEq(staker.totalPrepared(), 0, "totalPrepared");
        assertEq(staker.claimable(address(this)), 0, "claimable");
        assertEq(staker.claimable(bob), 0, "claimable");
        assertEq(staker.unstakeTime(address(this)), 0, "unstakeTime");
        assertEq(staker.unstakeTime(bob), 0, "unstakeTime");
    }

    function testRestakeReversWithNoUnstakePrepared() public {
        vm.expectRevert(IStaker.NoUnstakePrepared.selector);
        staker.restake();
    }

    function testRestake() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(staker), 100e18);
        staker.stake(100e18);
        staker.prepareUnstake();
        skip(Config.STAKER_UNSTAKE_DELAY / 2);
        staker.restake();
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(staker.balanceOf(address(this)), 100e18, "staker balance");
        assertEq(staker.totalStaked(), 100e18, "totalStaked");
        assertEq(staker.totalPrepared(), 0, "totalPrepared");
        assertEq(staker.claimable(address(this)), 0, "claimable");
        assertEq(staker.unstakeTime(address(this)), 0, "unstakeTime");
    }

    function testDonateRewards() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        _mintTokensFor(address(reward), address(this), rewardAmount);
        tlx.approve(address(staker), 100e18);
        staker.stake(100e18);
        reward.approve(address(staker), rewardAmount);
        staker.donateRewards(rewardAmount);
        assertEq(reward.balanceOf(address(this)), 0, "reward balance");
        assertEq(reward.balanceOf(address(staker)), rewardAmount);
        assertEq(staker.claimable(address(this)), rewardAmount, "claimable");
    }

    function testClaimingDisabled() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        _mintTokensFor(address(reward), address(this), rewardAmount);
        tlx.approve(address(staker), 100e18);
        staker.stake(100e18);
        reward.approve(address(staker), rewardAmount);
        staker.donateRewards(rewardAmount);
        uint256 claimable_ = staker.claimable(address(this));
        assertEq(claimable_, rewardAmount, "claimable");
        vm.expectRevert(IStaker.ClaimingNotEnabled.selector);
        staker.claim();
    }

    function testClaim() public {
        staker.enableClaiming();
        _mintTokensFor(address(tlx), address(this), 100e18);
        _mintTokensFor(address(reward), address(this), rewardAmount);
        tlx.approve(address(staker), 100e18);
        staker.stake(100e18);
        reward.approve(address(staker), rewardAmount);
        staker.donateRewards(rewardAmount);
        assertEq(reward.balanceOf(address(this)), 0, "reward balance");
        assertEq(reward.balanceOf(address(staker)), rewardAmount);
        uint256 claimable_ = staker.claimable(address(this));
        assertEq(claimable_, rewardAmount, "claimable");
        staker.claim();
        uint256 claimed_ = reward.balanceOf(address(this));
        assertEq(claimed_, claimable_, "claimed");
        assertEq(claimed_, rewardAmount);
        assertEq(reward.balanceOf(address(staker)), 0);
        assertEq(staker.claimable(address(this)), 0, "claimable");
    }

    function testNonOwnerCantEnableClaiming() public {
        vm.startPrank(alice);
        vm.expectRevert();
        staker.enableClaiming();
    }

    function testCantEnableClainmingTwice() public {
        staker.enableClaiming();
        vm.expectRevert(IStaker.ClaimingAlreadyEnabled.selector);
        staker.enableClaiming();
    }

    function testAccounting() public {
        uint256 tolerance_ = 1 * 10 ** rewardDecimals;

        // A Stakes 100
        _mintTokensFor(address(tlx), accountA, 100e18);
        vm.prank(accountA);
        tlx.approve(address(staker), 100e18);
        vm.prank(accountA);
        staker.stake(100e18);

        // B Stakes 200
        _mintTokensFor(address(tlx), accountB, 200e18);
        vm.prank(accountB);
        tlx.approve(address(staker), 200e18);
        vm.prank(accountB);
        staker.stake(200e18);

        // 100 Reward Tokens Donated
        uint256 donateAmountA = 100 * 10 ** rewardDecimals;
        _mintTokensFor(address(reward), address(this), donateAmountA);
        reward.approve(address(staker), donateAmountA);
        staker.donateRewards(donateAmountA);

        // Check accounting
        assertEq(staker.balanceOf(accountA), 100e18, "accountA balance");
        assertEq(staker.balanceOf(accountB), 200e18, "accountB balance");
        assertEq(staker.totalStaked(), 300e18, "totalStaked");
        assertEq(staker.totalPrepared(), 0, "totalPrepared");
        uint256 expectedA = donateAmountA / 3;
        assertApproxEqAbs(staker.claimable(accountA), expectedA, tolerance_);
        uint256 expectedB = (donateAmountA * 2) / 3;
        assertApproxEqAbs(staker.claimable(accountB), expectedB, tolerance_);

        // A Prepares Unstake
        vm.prank(accountA);
        staker.prepareUnstake();

        // 200 Reward Tokens Donated
        uint256 donateAmountB = 200 * 10 ** rewardDecimals;
        _mintTokensFor(address(reward), address(this), donateAmountB);
        reward.approve(address(staker), donateAmountB);
        staker.donateRewards(donateAmountB);

        // Check accounting
        assertEq(staker.balanceOf(accountA), 100e18, "accountA balance");
        assertEq(staker.balanceOf(accountB), 200e18, "accountB balance");
        assertEq(staker.totalStaked(), 300e18, "totalStaked");
        assertEq(staker.totalPrepared(), 100e18, "totalPrepared");
        expectedA = donateAmountA / 3;
        assertApproxEqAbs(staker.claimable(accountA), expectedA, tolerance_);
        expectedB = (donateAmountA * 2) / 3 + donateAmountB;
        assertApproxEqAbs(staker.claimable(accountB), expectedB, tolerance_);

        // C Stakes 300
        _mintTokensFor(address(tlx), accountC, 300e18);
        vm.prank(accountC);
        tlx.approve(address(staker), 300e18);
        vm.prank(accountC);
        staker.stake(300e18);

        // Check accounting
        assertEq(staker.balanceOf(accountA), 100e18, "accountA balance");
        assertEq(staker.balanceOf(accountB), 200e18, "accountB balance");
        assertEq(staker.balanceOf(accountC), 300e18, "accountC balance");
        assertEq(staker.totalStaked(), 600e18, "totalStaked");
        assertEq(staker.totalPrepared(), 100e18, "totalPrepared");
        expectedA = donateAmountA / 3;
        assertApproxEqAbs(staker.claimable(accountA), expectedA, tolerance_);
        expectedB = (donateAmountA * 2) / 3 + donateAmountB;
        assertApproxEqAbs(staker.claimable(accountB), expectedB, tolerance_);
        uint256 expectedC = 0;
        assertApproxEqAbs(staker.claimable(accountC), expectedC, tolerance_);

        // A Unstakes
        skip(Config.STAKER_UNSTAKE_DELAY);
        vm.prank(accountA);
        staker.unstake();

        // 300 Reward Tokens Donated
        uint256 donateAmountC = 300 * 10 ** rewardDecimals;
        _mintTokensFor(address(reward), address(this), donateAmountC);
        reward.approve(address(staker), donateAmountC);
        staker.donateRewards(donateAmountC);

        // Check accounting
        assertEq(staker.balanceOf(accountA), 0, "accountA balance");
        assertEq(staker.balanceOf(accountB), 200e18, "accountB balance");
        assertEq(staker.balanceOf(accountC), 300e18, "accountC balance");
        assertEq(staker.totalStaked(), 500e18, "totalStaked");
        assertEq(staker.totalPrepared(), 0, "totalPrepared");
        expectedA = donateAmountA / 3;
        assertApproxEqAbs(staker.claimable(accountA), expectedA, tolerance_);
        expectedB =
            (donateAmountA * 2) /
            3 +
            donateAmountB +
            (donateAmountC * 2) /
            5;
        assertApproxEqAbs(staker.claimable(accountB), expectedB, tolerance_);
        expectedC = (donateAmountC * 3) / 5;
        assertApproxEqAbs(staker.claimable(accountC), expectedC, tolerance_);
    }
}
