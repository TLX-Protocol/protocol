// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Tokens} from "../src/libraries/Tokens.sol";

import {PositionManager} from "../src/PositionManager.sol";
import {LeveragedToken} from "../src/LeveragedToken.sol";
import {IPositionManager} from "../src/interfaces/IPositionManager.sol";
import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";

contract PositionManagerTest is IntegrationTest {
    IPositionManager public positionManager;
    ILeveragedToken public leveragedToken;

    function setUp() public {
        positionManagerFactory.createPositionManager(Tokens.UNI);
        positionManager = PositionManager(
            positionManagerFactory.positionManager(Tokens.UNI)
        );
        (address longTokenAddress_, ) = leveragedTokenFactory
            .createLeveragedTokens(Tokens.UNI, 1.23e18);
        leveragedToken = LeveragedToken(longTokenAddress_);
    }

    function testInit() public {
        assertEq(positionManager.targetAsset(), Tokens.UNI);
        assertEq(
            positionManagerFactory.positionManager(Tokens.UNI),
            address(positionManager)
        );
    }

    function testMintAmountIn() public {
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), baseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), baseAmountIn);
        uint256 minLeveragedTokenAmountOut = 45e18;
        uint256 leveragedTokenAmountOut = positionManager.mintAmountIn(
            address(leveragedToken),
            baseAmountIn,
            minLeveragedTokenAmountOut
        );
        assertEq(leveragedTokenAmountOut, 50e18);
        assertEq(leveragedToken.totalSupply(), 50e18);
        assertEq(leveragedToken.balanceOf(address(this)), 50e18);
        assertEq(
            IERC20(Tokens.SUSD).balanceOf(address(positionManager)),
            100e18
        );
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(this)), 0);
    }

    function testMintAmountInRevertsForInvalidLeveragedToken() public {
        vm.expectRevert(IPositionManager.NotLeveragedToken.selector);
        positionManager.mintAmountIn(Tokens.UNI, 1, 1);
    }

    function testMintAmountInRevertsForInvalidPositionManager() public {
        positionManagerFactory.createPositionManager(Tokens.WBTC);
        (address longTokenAddress_, ) = leveragedTokenFactory
            .createLeveragedTokens(Tokens.WBTC, 1.23e18);
        vm.expectRevert(IPositionManager.NotPositionManager.selector);
        positionManager.mintAmountIn(longTokenAddress_, 1, 1);
    }

    function testMintAmountInRevertsForInsufficientAmount() public {
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), baseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), baseAmountIn);
        uint256 minLeveragedTokenAmountOut = 55e18;
        vm.expectRevert(IPositionManager.InsufficientAmount.selector);
        positionManager.mintAmountIn(
            address(leveragedToken),
            baseAmountIn,
            minLeveragedTokenAmountOut
        );
    }

    function testMintAmountOut() public {
        uint256 leveragedTokenAmountOut = 50e18;
        uint256 maxBaseAmountIn = 110e18;
        _mintTokensFor(Tokens.SUSD, address(this), maxBaseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), maxBaseAmountIn);
        uint256 baseAmountIn = positionManager.mintAmountOut(
            address(leveragedToken),
            leveragedTokenAmountOut,
            maxBaseAmountIn
        );
        assertEq(baseAmountIn, 100e18);
        assertEq(leveragedToken.totalSupply(), 50e18);
        assertEq(leveragedToken.balanceOf(address(this)), 50e18);
        assertEq(
            IERC20(Tokens.SUSD).balanceOf(address(positionManager)),
            100e18
        );
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(this)), 10e18);
    }

    function testMintAmountOutRevertsForInvalidLeveragedToken() public {
        vm.expectRevert(IPositionManager.NotLeveragedToken.selector);
        positionManager.mintAmountOut(Tokens.UNI, 1, 1);
    }

    function testMintAmountOutRevertsForInvalidPositionManager() public {
        positionManagerFactory.createPositionManager(Tokens.WBTC);
        (address longTokenAddress_, ) = leveragedTokenFactory
            .createLeveragedTokens(Tokens.WBTC, 1.23e18);

        vm.expectRevert(IPositionManager.NotPositionManager.selector);
        positionManager.mintAmountOut(longTokenAddress_, 1, 1);
    }

    function testMintAmountOutRevertsForInsufficientAmount() public {
        uint256 leveragedTokenAmountOut = 50e18;
        uint256 maxBaseAmountIn = 90e18;
        _mintTokensFor(Tokens.SUSD, address(this), maxBaseAmountIn);
        IERC20(Tokens.SUSD).approve(address(positionManager), maxBaseAmountIn);
        vm.expectRevert(IPositionManager.InsufficientAmount.selector);
        positionManager.mintAmountOut(
            address(leveragedToken),
            leveragedTokenAmountOut,
            maxBaseAmountIn
        );
    }

    function testRedeem() public {
        // Minting Leveraged Tokens
        uint256 baseAmountIn = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), baseAmountIn);
        uint256 minLeveragedTokenAmountOut = 50e18;
        IERC20(Tokens.SUSD).approve(address(positionManager), baseAmountIn);
        positionManager.mintAmountIn(
            address(leveragedToken),
            baseAmountIn,
            minLeveragedTokenAmountOut
        );
        assertEq(leveragedToken.balanceOf(address(this)), 50e18);

        // Redeeming Leveraged Tokens
        uint256 leveragedTokenAmountIn = 50e18;
        uint256 minBaseAmountOut = 90e18;
        uint256 baseAmountOut = positionManager.redeem(
            address(leveragedToken),
            leveragedTokenAmountIn,
            minBaseAmountOut
        );

        assertEq(baseAmountOut, 100e18);
        assertEq(leveragedToken.totalSupply(), 0);
        assertEq(leveragedToken.balanceOf(address(this)), 0);
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(positionManager)), 0);
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(this)), 100e18);
    }
}
