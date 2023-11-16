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
            .createLeveragedTokens(Symbols.UNI, 1.23e18);
        leveragedToken = LeveragedToken(longTokenAddress_);
        positionManager = IPositionManager(leveragedToken.positionManager());
    }

    function testInit() public {
        assertEq(
            address(positionManager.leveragedToken()),
            address(leveragedToken)
        );
    }

    function testMintAmountIn() public {
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), baseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), baseAmountIn);
        uint256 minLeveragedTokenAmountOut = 95e18;
        uint256 leveragedTokenAmountOut = positionManager.mintAmountIn(
            baseAmountIn,
            minLeveragedTokenAmountOut
        );
        assertEq(leveragedTokenAmountOut, 100e18);
        assertEq(leveragedToken.totalSupply(), 100e18);
        assertEq(leveragedToken.balanceOf(address(this)), 100e18);
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(positionManager)), 0);
        assertEq(
            synthetixHandler.remainingMargin(
                Symbols.UNI,
                address(positionManager)
            ),
            100e18
        );
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(this)), 0);
    }

    function testMintAmountInRevertsForInsufficientAmount() public {
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), baseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), baseAmountIn);
        uint256 minLeveragedTokenAmountOut = 110e18;
        vm.expectRevert(IPositionManager.InsufficientAmount.selector);
        positionManager.mintAmountIn(baseAmountIn, minLeveragedTokenAmountOut);
    }

    function testMintAmountOut() public {
        uint256 leveragedTokenAmountOut = 100e18;
        uint256 maxBaseAmountIn = 110e18;
        _mintTokensFor(Tokens.SUSD, address(this), maxBaseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), maxBaseAmountIn);
        uint256 baseAmountIn = positionManager.mintAmountOut(
            leveragedTokenAmountOut,
            maxBaseAmountIn
        );
        assertEq(baseAmountIn, 100e18);
        assertEq(leveragedToken.totalSupply(), 100e18);
        assertEq(leveragedToken.balanceOf(address(this)), 100e18);
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(positionManager)), 0);
        assertEq(
            synthetixHandler.remainingMargin(
                Symbols.UNI,
                address(positionManager)
            ),
            100e18
        );
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(this)), 10e18);
    }

    function testMintAmountOutRevertsForInsufficientAmount() public {
        uint256 leveragedTokenAmountOut = 100e18;
        uint256 maxBaseAmountIn = 90e18;
        _mintTokensFor(Tokens.SUSD, address(this), maxBaseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), maxBaseAmountIn);
        vm.expectRevert(IPositionManager.InsufficientAmount.selector);
        positionManager.mintAmountOut(leveragedTokenAmountOut, maxBaseAmountIn);
    }

    function testRedeem() public {
        // Minting Leveraged Tokens
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), baseAmountIn);
        uint256 minLeveragedTokenAmountOut = 100e18;
        IERC20(Tokens.SUSD).approve(address(positionManager), baseAmountIn);
        positionManager.mintAmountIn(baseAmountIn, minLeveragedTokenAmountOut);
        assertEq(leveragedToken.balanceOf(address(this)), 100e18);

        // Redeeming Leveraged Tokens
        uint256 leveragedTokenAmountIn = 100e18;
        uint256 minBaseAmountOut = 90e18;
        uint256 baseAmountOut = positionManager.redeem(
            leveragedTokenAmountIn,
            minBaseAmountOut
        );

        assertEq(baseAmountOut, 100e18);
        assertEq(leveragedToken.totalSupply(), 0);
        assertEq(leveragedToken.balanceOf(address(this)), 0);
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(positionManager)), 0);
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(this)), 100e18);
    }

    function testExchangeRate() public {
        assertEq(positionManager.exchangeRate(), 1e18);
        _mintTokens();
        assertApproxEqRel(positionManager.exchangeRate(), 1e18, 0.01e18);
    }

    function testCanRebalance() public {
        assertFalse(positionManager.canRebalance());
        _mintTokens();
        assertTrue(positionManager.canRebalance());
        // positionManager.rebalance();
        // assertFalse(positionManager.canRebalance());
        // TODO rebalance then check is false
        // TODO, add funds on bahalf of, then check is false
    }

    function _mintTokens() public {
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), baseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), baseAmountIn);
        positionManager.mintAmountIn(baseAmountIn, 0);
    }
}
