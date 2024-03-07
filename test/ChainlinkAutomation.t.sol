// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Symbols} from "../src/libraries/Symbols.sol";
import {Config} from "../src/libraries/Config.sol";
import {Errors} from "../src/libraries/Errors.sol";

import {ChainlinkAutomation} from "../src/ChainlinkAutomation.sol";

import {IChainlinkAutomation} from "../src/interfaces/IChainlinkAutomation.sol";
import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";

contract ChainlinkAutomationTest is IntegrationTest {
    ChainlinkAutomation internal chainlinkAutomation;

    function setUp() public override {
        super.setUp();
        chainlinkAutomation = new ChainlinkAutomation(
            address(addressProvider),
            Config.MAX_REBALANCES,
            Config.REBALANCE_BASE_NEXT_ATTEMPT_DELAY
        );
        addressProvider.addRebalancer(address(chainlinkAutomation));
    }

    function testInit() public {
        (bool upkeepNeeded, bytes memory performData) = chainlinkAutomation
            .checkUpkeep("");
        assertEq(upkeepNeeded, false);
        assertEq(performData.length, 0);
    }

    function testWithNoMintedLeveragedTokens() public {
        leveragedTokenFactory.createLeveragedTokens(
            Symbols.ETH,
            2e18,
            Config.REBALANCE_THRESHOLD
        );
        (bool upkeepNeeded, bytes memory performData) = chainlinkAutomation
            .checkUpkeep("");
        assertEq(upkeepNeeded, false);
        assertEq(performData.length, 0);
    }

    function testWithMintedLeveragedTokens() public {
        leveragedTokenFactory.createLeveragedTokens(
            Symbols.ETH,
            2e18,
            Config.REBALANCE_THRESHOLD
        );
        ILeveragedToken leveragedToken = ILeveragedToken(
            leveragedTokenFactory.allTokens()[0]
        );
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Config.BASE_ASSET, address(this), baseAmountIn);
        IERC20(Config.BASE_ASSET).approve(
            address(leveragedToken),
            baseAmountIn
        );
        leveragedToken.mint(baseAmountIn, 0);
        (bool upkeepNeeded, bytes memory performData) = chainlinkAutomation
            .checkUpkeep("");
        assertEq(upkeepNeeded, false);
        assertEq(performData.length, 0);
    }

    function testWithSomeUpkeeps() public {
        // Create tokens
        leveragedTokenFactory.createLeveragedTokens(
            Symbols.ETH,
            2e18,
            Config.REBALANCE_THRESHOLD
        );

        // Mint token
        ILeveragedToken leveragedToken = ILeveragedToken(
            leveragedTokenFactory.allTokens()[0]
        );
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Config.BASE_ASSET, address(this), baseAmountIn);
        IERC20(Config.BASE_ASSET).approve(
            address(leveragedToken),
            baseAmountIn
        );
        leveragedToken.mint(baseAmountIn, 0);
        _executeOrder(address(leveragedToken));

        // Modify price
        _modifyPrice(Symbols.ETH, 2e18);
        assertTrue(leveragedToken.canRebalance());

        // Validate
        (bool upkeepNeeded, bytes memory performData) = chainlinkAutomation
            .checkUpkeep("");
        address[] memory rebalancableTokens_ = abi.decode(
            performData,
            (address[])
        );
        assertEq(upkeepNeeded, true);
        assertEq(rebalancableTokens_.length, 1);

        // Execute
        vm.prank(chainlinkAutomation.forwarderAddress());
        chainlinkAutomation.performUpkeep(performData);
        _executeOrder(address(leveragedToken));

        // Validate
        (upkeepNeeded, performData) = chainlinkAutomation.checkUpkeep("");
        assertEq(upkeepNeeded, false);
    }

    function testRevertsWithNotForwarder() public {
        address[] memory rebalancableTokens = new address[](0);
        bytes memory performData = abi.encode(rebalancableTokens);
        vm.expectRevert(IChainlinkAutomation.NotForwarder.selector);
        chainlinkAutomation.performUpkeep(performData);
    }

    function testRevertsWithNoRebalanceTokens() public {
        address[] memory rebalancableTokens = new address[](0);
        bytes memory performData = abi.encode(rebalancableTokens);
        chainlinkAutomation.setForwarderAddress(address(this));
        vm.expectRevert(IChainlinkAutomation.NoRebalancableTokens.selector);
        chainlinkAutomation.performUpkeep(performData);
    }

    function testResetFailedCounterRevertsWhenZero() public {
        leveragedTokenFactory.createLeveragedTokens(
            Symbols.ETH,
            2e18,
            Config.REBALANCE_THRESHOLD
        );
        ILeveragedToken leveragedToken = ILeveragedToken(
            leveragedTokenFactory.allTokens()[0]
        );
        vm.expectRevert(Errors.SameAsCurrent.selector);
        chainlinkAutomation.resetFailedCounter(address(leveragedToken));
    }
}
