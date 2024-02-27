// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Tokens} from "../src/libraries/Tokens.sol";
import {Symbols} from "../src/libraries/Symbols.sol";
import {Config} from "../src/libraries/Config.sol";
import {Errors} from "../src/libraries/Errors.sol";

import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";

contract LeveragedTokenTest is IntegrationTest {
    ILeveragedToken public leveragedToken;

    function setUp() public override {
        super.setUp();
        (address longTokenAddress_, ) = leveragedTokenFactory
            .createLeveragedTokens(
                Symbols.ETH,
                2e18,
                Config.REBALANCE_THRESHOLD
            );
        leveragedToken = ILeveragedToken(longTokenAddress_);
    }

    function testInit() public {
        assertEq(leveragedToken.name(), "ETH 2x Long");
        assertEq(leveragedToken.symbol(), "ETH2L");
        assertEq(leveragedToken.decimals(), 18);
        assertEq(leveragedToken.targetAsset(), Symbols.ETH);
        assertEq(leveragedToken.targetLeverage(), 2e18);
        assertTrue(leveragedToken.isLong());
    }

    function testMint() public {
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Config.BASE_ASSET, address(this), baseAmountIn);
        IERC20(Config.BASE_ASSET).approve(
            address(leveragedToken),
            baseAmountIn
        );
        uint256 minLeveragedTokenAmountOut = 95e18;
        uint256 leveragedTokenAmountOut = leveragedToken.mint(
            baseAmountIn,
            minLeveragedTokenAmountOut
        );
        assertEq(leveragedTokenAmountOut, 100e18);
        assertEq(leveragedToken.totalSupply(), 100e18);
        assertEq(leveragedToken.balanceOf(address(this)), 100e18);
        assertEq(
            IERC20(Config.BASE_ASSET).balanceOf(address(leveragedToken)),
            0
        );
        assertApproxEqRel(
            synthetixHandler.remainingMargin(
                Symbols.ETH,
                address(leveragedToken)
            ),
            100e18,
            0.05e18
        );
        assertEq(IERC20(Config.BASE_ASSET).balanceOf(address(this)), 0);
    }

    function testMintRevertsForInsufficientAmount() public {
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Config.BASE_ASSET, address(this), baseAmountIn);
        IERC20(Config.BASE_ASSET).approve(
            address(leveragedToken),
            baseAmountIn
        );
        uint256 minLeveragedTokenAmountOut = 110e18;
        vm.expectRevert(ILeveragedToken.InsufficientAmount.selector);
        leveragedToken.mint(baseAmountIn, minLeveragedTokenAmountOut);
    }

    function testMintRevertsDuringLeverageUpdate() public {
        _mintTokens();
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Config.BASE_ASSET, address(this), baseAmountIn);
        IERC20(Config.BASE_ASSET).approve(
            address(leveragedToken),
            baseAmountIn
        );
        vm.expectRevert(ILeveragedToken.LeverageUpdatePending.selector);
        leveragedToken.mint(baseAmountIn, 0);
    }

    function testRedeem() public {
        // Minting Leveraged Tokens
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Config.BASE_ASSET, address(this), baseAmountIn);
        uint256 minLeveragedTokenAmountOut = 100e18;
        IERC20(Config.BASE_ASSET).approve(
            address(leveragedToken),
            baseAmountIn
        );
        leveragedToken.mint(baseAmountIn, minLeveragedTokenAmountOut);
        _executeOrder(address(leveragedToken));
        assertEq(leveragedToken.balanceOf(address(this)), 100e18);

        // Redeeming Leveraged Tokens
        uint256 leveragedTokenAmountIn = 1e18;
        uint256 minBaseAmountOut = 0.9e18;
        uint256 balanceBefore = IERC20(Config.BASE_ASSET).balanceOf(
            address(this)
        );
        uint256 baseAmountOut = leveragedToken.redeem(
            leveragedTokenAmountIn,
            minBaseAmountOut
        );
        uint256 balanceAfter = IERC20(Config.BASE_ASSET).balanceOf(
            address(this)
        );

        assertApproxEqRel(baseAmountOut, 1e18, 0.05e18, "1");
        assertEq(leveragedToken.totalSupply(), 99e18);
        assertEq(leveragedToken.balanceOf(address(this)), 99e18);
        assertApproxEqRel(balanceAfter - balanceBefore, 1e18, 0.05e18, "2");
    }

    function testRedeemRevertsDuringLeverageUpdate() public {
        _mintTokens();
        vm.expectRevert(ILeveragedToken.LeverageUpdatePending.selector);
        leveragedToken.redeem(1e18, 0);
    }

    function testExchangeRate() public {
        assertEq(leveragedToken.exchangeRate(), 1e18);
        _mintTokens();
        _executeOrder(address(leveragedToken));
        assertApproxEqRel(leveragedToken.exchangeRate(), 1e18, 0.05e18);
    }

    function testCanRebalance() public {
        assertFalse(leveragedToken.canRebalance(), "1");
        _mintTokens();
        assertFalse(leveragedToken.canRebalance(), "2");
        _executeOrder(address(leveragedToken));

        assertFalse(leveragedToken.canRebalance(), "3");
        _mintTokens();
        _executeOrder(address(leveragedToken));
        assertFalse(leveragedToken.canRebalance(), "4");
    }

    function testRebalance() public {
        _mintTokens();
        _executeOrder(address(leveragedToken));
        assertApproxEqRel(
            synthetixHandler.leverage(Symbols.ETH, address(leveragedToken)),
            2e18,
            0.1e18
        );
        _mintTokens();
        assertApproxEqRel(
            synthetixHandler.leverage(Symbols.ETH, address(leveragedToken)),
            2e18 / 2,
            0.1e18
        );
        assertFalse(leveragedToken.canRebalance());
    }

    function testChargeStreamingFee() public {
        // Getting some TLX tokens for Alice (via vesting)
        skip(2);
        vm.startPrank(alice);
        vesting.claim();

        // Stake some tokens from alice
        uint256 aliceTlxBalance = tlx.balanceOf(alice);
        tlx.approve(address(staker), aliceTlxBalance);
        staker.stake(aliceTlxBalance);
        vm.stopPrank();

        // Minting tokens
        _mintTokens();
        _executeOrder(address(leveragedToken));
        uint256 delay_ = 1 minutes;
        skip(delay_);

        // Charging fees
        uint256 feesBefore_ = IERC20(Config.BASE_ASSET).balanceOf(
            address(staker)
        );
        leveragedToken.chargeStreamingFee();
        uint256 feesAfter_ = IERC20(Config.BASE_ASSET).balanceOf(
            address(staker)
        );
        uint256 notional_ = synthetixHandler.notionalValue(
            Symbols.ETH,
            address(leveragedToken)
        );
        uint256 streamingFee_ = parameterProvider.streamingFee();
        uint256 annualFee_ = (notional_ * streamingFee_) / 1e18;
        uint256 expectedFee_ = (annualFee_ * delay_) / 365 days;
        uint256 gained_ = feesAfter_ - feesBefore_;
        assertGt(gained_, 0);
        assertApproxEqRel(gained_, expectedFee_, 0.05e18);
    }

    function testCanNotRebalanceIfNotRebalancer() public {
        vm.startPrank(alice);
        vm.expectRevert(Errors.NotAuthorized.selector);
        leveragedToken.rebalance();
    }

    function testLeveragedTokenWithMaxLeverage() public {
        leveragedTokenFactory.createLeveragedTokens(
            Symbols.ETH,
            Config.MAX_LEVERAGE,
            Config.REBALANCE_THRESHOLD
        );
        leveragedToken = ILeveragedToken(
            leveragedTokenFactory.token(Symbols.ETH, Config.MAX_LEVERAGE, true)
        );
        _mintTokens();
        _executeOrder(address(leveragedToken));
        assertApproxEqRel(
            synthetixHandler.leverage(Symbols.ETH, address(leveragedToken)),
            Config.MAX_LEVERAGE,
            0.1e18
        );
        _mintTokens();
        _executeOrder(address(leveragedToken));
        assertApproxEqRel(
            synthetixHandler.leverage(Symbols.ETH, address(leveragedToken)),
            Config.MAX_LEVERAGE,
            0.1e18
        );
    }

    function testPayingFees() public {
        // Getting some TLX tokens for Alice (via vesting)
        skip(2);
        vm.startPrank(alice);
        vesting.claim();

        // Stake some tokens from alice
        uint256 aliceTlxBalance = tlx.balanceOf(alice);
        tlx.approve(address(staker), aliceTlxBalance);
        staker.stake(aliceTlxBalance);
        vm.stopPrank();

        // Minting Leveraged Tokens
        uint256 amount = 100e18;
        _mintTokensFor(Config.BASE_ASSET, address(this), amount);
        IERC20 base = IERC20(Config.BASE_ASSET);
        base.approve(address(leveragedToken), amount);
        leveragedToken.mint(amount, 0);
        _executeOrder(address(leveragedToken));
        assertEq(leveragedToken.balanceOf(address(this)), amount);

        // Redeeming Leveraged Tokens
        assertEq(base.balanceOf(address(staker)), 0);
        uint256 baseHeld = base.balanceOf(address(leveragedToken));
        assertEq(baseHeld, 0);
        leveragedToken.redeem(amount / 10, 0);
        assertGt(base.balanceOf(address(staker)), 0);
    }

    function testMaxBaseAssetAmount() public {
        uint256 baseAmountIn = 100_000_000_000e18;
        _mintTokensFor(Config.BASE_ASSET, address(this), baseAmountIn);
        IERC20(Config.BASE_ASSET).approve(
            address(leveragedToken),
            baseAmountIn
        );
        uint256 minLeveragedTokenAmountOut = 95e18;
        vm.expectRevert(ILeveragedToken.ExceedsLimit.selector);
        leveragedToken.mint(baseAmountIn, minLeveragedTokenAmountOut);
    }

    function testPause() public {
        assertFalse(leveragedToken.isPaused());
        vm.prank(alice);
        vm.expectRevert();
        leveragedToken.setIsPaused(true);
        vm.expectRevert(Errors.SameAsCurrent.selector);
        leveragedToken.setIsPaused(false);
        leveragedToken.setIsPaused(true);
        assertTrue(leveragedToken.isPaused());
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Config.BASE_ASSET, address(this), baseAmountIn);
        IERC20(Config.BASE_ASSET).approve(
            address(leveragedToken),
            baseAmountIn
        );
        vm.expectRevert(ILeveragedToken.Paused.selector);
        leveragedToken.mint(baseAmountIn, 0);
        vm.expectRevert(Errors.SameAsCurrent.selector);
        leveragedToken.setIsPaused(true);
        leveragedToken.setIsPaused(false);
        leveragedToken.mint(baseAmountIn, 0);
    }

    function _mintTokens() public {
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Config.BASE_ASSET, address(this), baseAmountIn);
        IERC20(Config.BASE_ASSET).approve(
            address(leveragedToken),
            baseAmountIn
        );
        leveragedToken.mint(baseAmountIn, 0);
    }
}
