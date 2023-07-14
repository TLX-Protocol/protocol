// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Config} from "../src/libraries/Config.sol";

import {ILocker} from "../src/interfaces/ILocker.sol";

contract LockerTest is IntegrationTest {
    IERC20Metadata public reward;
    uint8 public rewardDecimals;
    uint256 public rewardAmount;

    address public accountA = makeAddr("accountA");
    address public accountB = makeAddr("accountB");
    address public accountC = makeAddr("accountC");
    address public accountD = makeAddr("accountD");

    function setUp() public {
        reward = IERC20Metadata(Config.REWARD_TOKEN);
        rewardDecimals = reward.decimals();
        rewardAmount = 100 * 10 ** rewardDecimals;
    }

    function testInit() public {
        assertEq(locker.name(), "Staked TLX Token", "name");
        assertEq(locker.symbol(), "stTLX", "symbol");
        assertEq(locker.decimals(), 18, "decimals");
        assertEq(locker.balanceOf(address(this)), 0, "balanceOf");
        assertEq(locker.totalLocked(), 0, "totalLocked");
        assertEq(locker.totalPrepared(), 0, "totalPrepared");
        assertEq(locker.claimable(address(this)), 0, "claimable");
        assertEq(locker.unlockTime(address(this)), 0, "unlockTime");
        assertEq(locker.isUnlocked(address(this)), false, "isUnlocked");
        assertEq(locker.unlockDelay(), Config.LOCKER_UNLOCK_DELAY);
        assertEq(locker.rewardToken(), Config.REWARD_TOKEN, "rewardToken");
    }

    function testLock() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(locker), 100e18);
        locker.lock(100e18);
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(locker.balanceOf(address(this)), 100e18, "locker balance");
        assertEq(locker.totalLocked(), 100e18, "totalLocked");
        assertEq(locker.totalPrepared(), 0, "totalPrepared");
        assertEq(locker.claimable(address(this)), 0, "claimable");
        assertEq(locker.unlockTime(address(this)), 0, "unlockTime");
        assertEq(locker.isUnlocked(address(this)), false, "isUnlocked");
    }

    function testLockRevertsWithZeroAmount() public {
        vm.expectRevert(ILocker.ZeroAmount.selector);
        locker.lock(0);
    }

    function testLockRevertsWithZeroAddress() public {
        vm.expectRevert(ILocker.ZeroAddress.selector);
        locker.lockFor(100e18, address(0));
    }

    function testLockFor() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(locker), 100e18);
        locker.lockFor(100e18, bob);
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(locker.balanceOf(address(this)), 0, "locker balance");
        assertEq(locker.balanceOf(bob), 100e18, "locker balance");
        assertEq(locker.totalLocked(), 100e18, "totalLocked");
        assertEq(locker.totalPrepared(), 0, "totalPrepared");
        assertEq(locker.claimable(address(this)), 0, "claimable");
        assertEq(locker.claimable(bob), 0, "claimable");
        assertEq(locker.unlockTime(address(this)), 0, "unlockTime");
        assertEq(locker.unlockTime(bob), 0, "unlockTime");
        assertEq(locker.isUnlocked(address(this)), false, "isUnlocked");
        assertEq(locker.isUnlocked(bob), false, "isUnlocked");
    }

    function testPrepareUnlock() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(locker), 100e18);
        locker.lock(100e18);
        locker.prepareUnlock();
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(locker.balanceOf(address(this)), 100e18, "locker balance");
        assertEq(locker.totalLocked(), 100e18, "totalLocked");
        assertEq(locker.totalPrepared(), 100e18, "totalPrepared");
        assertEq(locker.claimable(address(this)), 0, "claimable");
        assertEq(
            locker.unlockTime(address(this)),
            block.timestamp + Config.LOCKER_UNLOCK_DELAY,
            "unlockTime"
        );
        assertEq(locker.isUnlocked(address(this)), false, "isUnlocked");
    }

    function testUnlockFailsWithZeroBalance() public {
        vm.expectRevert(ILocker.ZeroBalance.selector);
        locker.unlock();
    }

    function testUnlockFailsWithNoUnlockPrepared() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(locker), 100e18);
        locker.lock(100e18);
        vm.expectRevert(ILocker.NoUnlockPrepared.selector);
        locker.unlock();
    }

    function testUnlockFailsWithNotUnlocked() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(locker), 100e18);
        locker.lock(100e18);
        locker.prepareUnlock();
        vm.expectRevert(ILocker.NotUnlocked.selector);
        locker.unlock();
    }

    function testUnlock() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(locker), 100e18);
        locker.lock(100e18);
        locker.prepareUnlock();
        assertEq(locker.isUnlocked(address(this)), false, "isUnlocked");
        skip(Config.LOCKER_UNLOCK_DELAY);
        assertEq(locker.isUnlocked(address(this)), true, "isUnlocked");
        locker.unlock();
        assertEq(tlx.balanceOf(address(this)), 100e18, "tlx balance");
        assertEq(locker.balanceOf(address(this)), 0, "locker balance");
        assertEq(locker.totalLocked(), 0, "totalLocked");
        assertEq(locker.totalPrepared(), 0, "totalPrepared");
        assertEq(locker.claimable(address(this)), 0, "claimable");
        assertEq(locker.unlockTime(address(this)), 0, "unlockTime");
    }

    function testUnlockFor() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(locker), 100e18);
        locker.lock(100e18);
        locker.prepareUnlock();
        assertEq(locker.isUnlocked(address(this)), false, "isUnlocked");
        assertEq(locker.isUnlocked(bob), false, "isUnlocked");
        skip(Config.LOCKER_UNLOCK_DELAY);
        assertEq(locker.isUnlocked(address(this)), true, "isUnlocked");
        assertEq(locker.isUnlocked(bob), false, "isUnlocked");
        locker.unlockFor(bob);
        assertEq(tlx.balanceOf(bob), 100e18, "tlx balance");
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(locker.balanceOf(address(this)), 0, "locker balance");
        assertEq(locker.balanceOf(bob), 0, "locker balance");
        assertEq(locker.totalLocked(), 0, "totalLocked");
        assertEq(locker.totalPrepared(), 0, "totalPrepared");
        assertEq(locker.claimable(address(this)), 0, "claimable");
        assertEq(locker.claimable(bob), 0, "claimable");
        assertEq(locker.unlockTime(address(this)), 0, "unlockTime");
        assertEq(locker.unlockTime(bob), 0, "unlockTime");
    }

    function testRelockReversWithNoUnlockPrepared() public {
        vm.expectRevert(ILocker.NoUnlockPrepared.selector);
        locker.relock();
    }

    function testRelock() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        tlx.approve(address(locker), 100e18);
        locker.lock(100e18);
        locker.prepareUnlock();
        skip(Config.LOCKER_UNLOCK_DELAY / 2);
        locker.relock();
        assertEq(tlx.balanceOf(address(this)), 0, "tlx balance");
        assertEq(locker.balanceOf(address(this)), 100e18, "locker balance");
        assertEq(locker.totalLocked(), 100e18, "totalLocked");
        assertEq(locker.totalPrepared(), 0, "totalPrepared");
        assertEq(locker.claimable(address(this)), 0, "claimable");
        assertEq(locker.unlockTime(address(this)), 0, "unlockTime");
    }

    function testDonateRewards() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        _mintTokensFor(address(reward), address(this), rewardAmount);
        tlx.approve(address(locker), 100e18);
        locker.lock(100e18);
        reward.approve(address(locker), rewardAmount);
        locker.donateRewards(rewardAmount);
        assertEq(reward.balanceOf(address(this)), 0, "reward balance");
        assertEq(reward.balanceOf(address(locker)), rewardAmount);
        assertEq(locker.claimable(address(this)), rewardAmount, "claimable");
    }

    function testClaim() public {
        _mintTokensFor(address(tlx), address(this), 100e18);
        _mintTokensFor(address(reward), address(this), rewardAmount);
        tlx.approve(address(locker), 100e18);
        locker.lock(100e18);
        reward.approve(address(locker), rewardAmount);
        locker.donateRewards(rewardAmount);
        assertEq(reward.balanceOf(address(this)), 0, "reward balance");
        assertEq(reward.balanceOf(address(locker)), rewardAmount);
        uint256 claimable_ = locker.claimable(address(this));
        assertEq(claimable_, rewardAmount, "claimable");
        locker.claim();
        uint256 claimed_ = reward.balanceOf(address(this));
        assertEq(claimed_, claimable_, "claimed");
        assertEq(claimed_, rewardAmount);
        assertEq(reward.balanceOf(address(locker)), 0);
        assertEq(locker.claimable(address(this)), 0, "claimable");
    }

    function testAccounting() public {
        // TODO after one user unlocks, the others keep earning

        uint256 tolerance_ = 1 * 10 ** rewardDecimals;

        // A Locks 100
        _mintTokensFor(address(tlx), accountA, 100e18);
        vm.prank(accountA);
        tlx.approve(address(locker), 100e18);
        vm.prank(accountA);
        locker.lock(100e18);

        // B Locks 200
        _mintTokensFor(address(tlx), accountB, 200e18);
        vm.prank(accountB);
        tlx.approve(address(locker), 200e18);
        vm.prank(accountB);
        locker.lock(200e18);

        // 100 Reward Tokens Donated
        uint256 donateAmountA = 100 * 10 ** rewardDecimals;
        _mintTokensFor(address(reward), address(this), donateAmountA);
        reward.approve(address(locker), donateAmountA);
        locker.donateRewards(donateAmountA);

        // Check accounting
        assertEq(locker.balanceOf(accountA), 100e18, "accountA balance");
        assertEq(locker.balanceOf(accountB), 200e18, "accountB balance");
        assertEq(locker.totalLocked(), 300e18, "totalLocked");
        assertEq(locker.totalPrepared(), 0, "totalPrepared");
        uint256 expectedA = donateAmountA / 3;
        assertApproxEqAbs(locker.claimable(accountA), expectedA, tolerance_);
        uint256 expectedB = (donateAmountA * 2) / 3;
        assertApproxEqAbs(locker.claimable(accountB), expectedB, tolerance_);

        // A Prepares Unlock
        vm.prank(accountA);
        locker.prepareUnlock();

        // 200 Reward Tokens Donated
        uint256 donateAmountB = 200 * 10 ** rewardDecimals;
        _mintTokensFor(address(reward), address(this), donateAmountB);
        reward.approve(address(locker), donateAmountB);
        locker.donateRewards(donateAmountB);

        // Check accounting
        assertEq(locker.balanceOf(accountA), 100e18, "accountA balance");
        assertEq(locker.balanceOf(accountB), 200e18, "accountB balance");
        assertEq(locker.totalLocked(), 300e18, "totalLocked");
        assertEq(locker.totalPrepared(), 100e18, "totalPrepared");
        expectedA = donateAmountA / 3;
        assertApproxEqAbs(locker.claimable(accountA), expectedA, tolerance_);
        expectedB = (donateAmountA * 2) / 3 + donateAmountB;
        assertApproxEqAbs(locker.claimable(accountB), expectedB, tolerance_);

        // C Locks 300
        _mintTokensFor(address(tlx), accountC, 300e18);
        vm.prank(accountC);
        tlx.approve(address(locker), 300e18);
        vm.prank(accountC);
        locker.lock(300e18);

        // Check accounting
        assertEq(locker.balanceOf(accountA), 100e18, "accountA balance");
        assertEq(locker.balanceOf(accountB), 200e18, "accountB balance");
        assertEq(locker.balanceOf(accountC), 300e18, "accountC balance");
        assertEq(locker.totalLocked(), 600e18, "totalLocked");
        assertEq(locker.totalPrepared(), 100e18, "totalPrepared");
        expectedA = donateAmountA / 3;
        assertApproxEqAbs(locker.claimable(accountA), expectedA, tolerance_);
        expectedB = (donateAmountA * 2) / 3 + donateAmountB;
        assertApproxEqAbs(locker.claimable(accountB), expectedB, tolerance_);
        uint256 expectedC = 0;
        assertApproxEqAbs(locker.claimable(accountC), expectedC, tolerance_);

        // A Unlocks
        skip(Config.LOCKER_UNLOCK_DELAY);
        vm.prank(accountA);
        locker.unlock();

        // 300 Reward Tokens Donated
        uint256 donateAmountC = 300 * 10 ** rewardDecimals;
        _mintTokensFor(address(reward), address(this), donateAmountC);
        reward.approve(address(locker), donateAmountC);
        locker.donateRewards(donateAmountC);

        // Check accounting
        assertEq(locker.balanceOf(accountA), 0, "accountA balance");
        assertEq(locker.balanceOf(accountB), 200e18, "accountB balance");
        assertEq(locker.balanceOf(accountC), 300e18, "accountC balance");
        assertEq(locker.totalLocked(), 500e18, "totalLocked");
        assertEq(locker.totalPrepared(), 0, "totalPrepared");
        expectedA = donateAmountA / 3;
        assertApproxEqAbs(locker.claimable(accountA), expectedA, tolerance_);
        expectedB =
            (donateAmountA * 2) /
            3 +
            donateAmountB +
            (donateAmountC * 2) /
            5;
        assertApproxEqAbs(locker.claimable(accountB), expectedB, tolerance_);
        expectedC = (donateAmountC * 3) / 5;
        assertApproxEqAbs(locker.claimable(accountC), expectedC, tolerance_);
    }
}
