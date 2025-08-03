// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {AddressKeys} from "../src/libraries/AddressKeys.sol";
import {Config} from "../src/libraries/Config.sol";
import {Contracts} from "../src/libraries/Contracts.sol";

import {ITlxToken} from "../src/interfaces/ITlxToken.sol";
import {VelodromeVoterAutomation} from "../src/helpers/VelodromeVoterAutomation.sol";

contract VelodromeVoterRunnerTest is IntegrationTest {
    uint256 constant PRECISION = 0.001e18; // 0.1%

    function setUp() public override {
        super.setUp();

        // Transferring the TLX to the voter runner
        uint256 balance_ = tlx.balanceOf(Config.AMM_DISTRIBUTOR);
        vm.prank(Config.AMM_DISTRIBUTOR);
        tlx.transfer(address(voterAutomation), balance_ / 2);
    }

    function testRecoverTokens() public {
        address owner_ = addressProvider.owner();
        uint256 runnerBefore_ = tlx.balanceOf(address(voterAutomation));
        assertGt(runnerBefore_, 0, "balanceBefore");
        uint256 balanceBefore_ = tlx.balanceOf(address(this));
        vm.expectRevert();
        vm.prank(alice);
        voterAutomation.recoverTokens(address(tlx), address(this));
        vm.prank(owner_);
        voterAutomation.recoverTokens(address(tlx), address(this));
        uint256 runnerAfter_ = tlx.balanceOf(address(voterAutomation));
        assertEq(runnerAfter_, 0, "balanceAfter");
        uint256 balanceAfter_ = tlx.balanceOf(address(this));
        assertEq(balanceAfter_, balanceBefore_ + runnerBefore_, "balanceAfter");
    }

    function testRun() public {
        skip(1 days);
        (bool upkeepNeeded, ) = voterAutomation.checkUpkeep("");
        assertTrue(upkeepNeeded, "canRun");
        uint256 tlxBefore_ = tlx.balanceOf(Contracts.TLX_ETH_REWARDS);
        voterAutomation.performUpkeep("");
        uint256 tlxAfter_ = tlx.balanceOf(Contracts.TLX_ETH_REWARDS);
        uint256 tlxGained_ = tlxAfter_ - tlxBefore_;
        assertApproxEqRel(tlxGained_, 98_006.40e18, PRECISION, "tlxGained");
    }

    function testCanNotRun() public {
        skip(1 days);
        (bool upkeepNeeded, ) = voterAutomation.checkUpkeep("");
        assertTrue(upkeepNeeded, "canRun");
        voterAutomation.performUpkeep("");
        vm.expectRevert(VelodromeVoterAutomation.CanNotRun.selector);
        voterAutomation.performUpkeep("");
    }

    function testRunMany() public {
        skip(1 days);
        _testRun(98_006.40e18);
        _testRun(98_006.40e18);
        _testRun(97_614.35e18);
        _testRun(95_262.04e18);
        _testRun(95_262.04e18);
        _testRun(94_499.90e18);
        _testRun(92_594.53e18);
        _testRun(92_594.53e18);
        _testRun(91_483.32e18);
        _testRun(90_001.71e18);
        _testRun(90_001.71e18);
    }

    function testRunWithDelay() public {
        VelodromeVoterAutomation delayedRunner = new VelodromeVoterAutomation(
            address(addressProvider),
            Config.VOTER_INITIAL_TLX_PER_SECOND,
            Config.PERIOD_DECAY_MULTIPLIER,
            Config.PERIOD_DURATION,
            block.timestamp - 1 days,
            Contracts.TLX_ETH_REWARDS,
            block.timestamp - 7 days * 3 - 1 days,
            293_627.15e18
        );
        uint256 balance_ = tlx.balanceOf(Config.AMM_DISTRIBUTOR);
        vm.prank(Config.AMM_DISTRIBUTOR);
        tlx.transfer(address(delayedRunner), balance_);
        uint256 tlxBefore_ = tlx.balanceOf(Contracts.TLX_ETH_REWARDS);
        delayedRunner.performUpkeep("");
        uint256 tlxAfter_ = tlx.balanceOf(Contracts.TLX_ETH_REWARDS);
        uint256 tlxGained_ = tlxAfter_ - tlxBefore_;
        assertApproxEqRel(tlxGained_, 95_262.04e18, PRECISION, "tlxGained");
    }

    function _testRun(uint256 expected_) internal {
        uint256 tlxBefore_ = tlx.balanceOf(Contracts.TLX_ETH_REWARDS);
        voterAutomation.performUpkeep("");
        uint256 tlxAfter_ = tlx.balanceOf(Contracts.TLX_ETH_REWARDS);
        uint256 tlxGained_ = tlxAfter_ - tlxBefore_;
        assertApproxEqRel(tlxGained_, expected_, PRECISION, "tlxGained");
        skip(7 days);
    }
}
