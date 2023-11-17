// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Tokens} from "../src/libraries/Tokens.sol";
import {Symbols} from "../src/libraries/Symbols.sol";

import {PositionManager} from "../src/PositionManager.sol";
import {LeveragedToken} from "../src/LeveragedToken.sol";
import {IPositionManager} from "../src/interfaces/IPositionManager.sol";
import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";

contract PositionManagerTest is IntegrationTest {
    IPositionManager public positionManager;
    ILeveragedToken public leveragedToken;

    function setUp() public {
        (address longTokenAddress_, ) = leveragedTokenFactory
            .createLeveragedTokens(Symbols.ETH, 1.23e18);
        leveragedToken = LeveragedToken(longTokenAddress_);
        positionManager = IPositionManager(leveragedToken.positionManager());
    }

    function testInit() public {
        assertEq(
            address(positionManager.leveragedToken()),
            address(leveragedToken)
        );
    }

    function testMint() public {
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), baseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), baseAmountIn);
        uint256 minLeveragedTokenAmountOut = 95e18;
        uint256 leveragedTokenAmountOut = positionManager.mint(
            baseAmountIn,
            minLeveragedTokenAmountOut
        );
        assertEq(leveragedTokenAmountOut, 100e18);
        assertEq(leveragedToken.totalSupply(), 100e18);
        assertEq(leveragedToken.balanceOf(address(this)), 100e18);
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(positionManager)), 0);
        assertApproxEqRel(
            synthetixHandler.remainingMargin(
                Symbols.ETH,
                address(positionManager)
            ),
            100e18,
            0.05e18
        );
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(this)), 0);
    }

    function testMintRevertsForInsufficientAmount() public {
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), baseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), baseAmountIn);
        uint256 minLeveragedTokenAmountOut = 110e18;
        vm.expectRevert(IPositionManager.InsufficientAmount.selector);
        positionManager.mint(baseAmountIn, minLeveragedTokenAmountOut);
    }

    function testMintRevertsDuringLeverageUpdate() public {
        _mintTokens();
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), baseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), baseAmountIn);
        vm.expectRevert(IPositionManager.LeverageUpdatePending.selector);
        positionManager.mint(baseAmountIn, 0);
    }

    function testRedeem() public {
        // Minting Leveraged Tokens
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), baseAmountIn);
        uint256 minLeveragedTokenAmountOut = 100e18;
        IERC20(Tokens.SUSD).approve(address(positionManager), baseAmountIn);
        positionManager.mint(baseAmountIn, minLeveragedTokenAmountOut);
        _executeOrder(address(positionManager));
        assertEq(leveragedToken.balanceOf(address(this)), 100e18);

        // Redeeming Leveraged Tokens
        uint256 leveragedTokenAmountIn = 1e18;
        uint256 minBaseAmountOut = 0.9e18;
        uint256 balanceBefore = IERC20(Tokens.SUSD).balanceOf(address(this));
        uint256 baseAmountOut = positionManager.redeem(
            leveragedTokenAmountIn,
            minBaseAmountOut
        );
        uint256 balanceAfter = IERC20(Tokens.SUSD).balanceOf(address(this));

        assertApproxEqRel(baseAmountOut, 1e18, 0.05e18, "1");
        assertEq(leveragedToken.totalSupply(), 99e18);
        assertEq(leveragedToken.balanceOf(address(this)), 99e18);
        assertApproxEqRel(balanceAfter - balanceBefore, 1e18, 0.05e18, "2");
    }

    function testRedeemRevertsDuringLeverageUpdate() public {
        _mintTokens();
        vm.expectRevert(IPositionManager.LeverageUpdatePending.selector);
        positionManager.redeem(1e18, 0);
    }

    function testExchangeRate() public {
        assertEq(positionManager.exchangeRate(), 1e18);
        _mintTokens();
        _executeOrder(address(positionManager));
        assertApproxEqRel(positionManager.exchangeRate(), 1e18, 0.05e18);
    }

    function testCanRebalance() public {
        assertFalse(positionManager.canRebalance(), "1");
        _mintTokens();
        assertFalse(positionManager.canRebalance(), "2");
        _executeOrder(address(positionManager));

        assertFalse(positionManager.canRebalance(), "3");
        _mintTokens();
        _executeOrder(address(positionManager));
        assertFalse(positionManager.canRebalance(), "4");
    }

    function testRebalance() public {
        _mintTokens();
        _executeOrder(address(positionManager));
        assertApproxEqRel(
            synthetixHandler.leverage(Symbols.ETH, address(positionManager)),
            1.23e18,
            0.05e18
        );
        _mintTokens();
        assertApproxEqRel(
            synthetixHandler.leverage(Symbols.ETH, address(positionManager)),
            1.23e18 / 2,
            0.05e18
        );
    }

    function _mintTokens() public {
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), baseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), baseAmountIn);
        positionManager.mint(baseAmountIn, 0);
    }
}
