// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Errors} from "../../src/libraries/Errors.sol";
import {Symbols} from "../src/libraries/Symbols.sol";

import {ILeveragedTokenFactory} from "../src/interfaces/ILeveragedTokenFactory.sol";
import {Tokens} from "../src/libraries/Tokens.sol";
import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";

contract LeveragedTokenleveragedTokenFactoryTest is IntegrationTest {
    function setUp() public {
        positionManagerFactory.createPositionManager(Symbols.UNI);
    }

    function testDeployTokens() public {
        (
            address longTokenAddress_,
            address shortTokenAddress_
        ) = leveragedTokenFactory.createLeveragedTokens(Symbols.UNI, 1.23e18);
        ILeveragedToken longToken = ILeveragedToken(longTokenAddress_);
        ILeveragedToken shortToken = ILeveragedToken(shortTokenAddress_);
        assertEq(longToken.name(), "UNI 1.23x Long");
        assertEq(longToken.symbol(), "UNI1.23L");
        assertEq(longToken.decimals(), 18);
        assertEq(longToken.targetAsset(), Symbols.UNI);
        assertEq(longToken.targetLeverage(), 1.23e18);
        assertTrue(longToken.isLong());
        assertEq(shortToken.name(), "UNI 1.23x Short");
        assertEq(shortToken.symbol(), "UNI1.23S");
        assertEq(shortToken.decimals(), 18);
        assertEq(shortToken.targetAsset(), Symbols.UNI);
        assertEq(shortToken.targetLeverage(), 1.23e18);
        assertFalse(shortToken.isLong());
        address[] memory tokens = leveragedTokenFactory.allTokens();
        assertEq(tokens.length, 2);
        assertEq(tokens[0], longTokenAddress_);
        assertEq(tokens[1], shortTokenAddress_);
        address[] memory longTokens = leveragedTokenFactory.longTokens();
        assertEq(longTokens.length, 1);
        assertEq(longTokens[0], longTokenAddress_);
        address[] memory shortTokens = leveragedTokenFactory.shortTokens();
        assertEq(shortTokens.length, 1);
        assertEq(shortTokens[0], shortTokenAddress_);
        address[] memory allTargetTokens = leveragedTokenFactory.allTokens(
            Symbols.UNI
        );
        assertEq(allTargetTokens.length, 2);
        assertEq(allTargetTokens[0], longTokenAddress_);
        assertEq(allTargetTokens[1], shortTokenAddress_);
        address[] memory emptyTokens = leveragedTokenFactory.allTokens(
            Symbols.USDC
        );
        assertEq(emptyTokens.length, 0);
        address[] memory longTargetTokens = leveragedTokenFactory.longTokens(
            Symbols.UNI
        );
        assertEq(longTargetTokens.length, 1);
        assertEq(longTargetTokens[0], longTokenAddress_);
        address[] memory shortTargetTokens = leveragedTokenFactory.shortTokens(
            Symbols.UNI
        );
        assertEq(shortTargetTokens.length, 1);
        assertEq(shortTargetTokens[0], shortTokenAddress_);
        address longTokenAddress = leveragedTokenFactory.token(
            Symbols.UNI,
            1.23e18,
            true
        );
        assertEq(longTokenAddress, longTokenAddress_);
        address shortTokenAddress = leveragedTokenFactory.token(
            Symbols.UNI,
            1.23e18,
            false
        );
        assertEq(shortTokenAddress, shortTokenAddress_);
        assertTrue(
            leveragedTokenFactory.tokenExists(Symbols.UNI, 1.23e18, true)
        );
        assertTrue(
            leveragedTokenFactory.tokenExists(Symbols.UNI, 1.23e18, false)
        );
        assertEq(
            leveragedTokenFactory.pair(longTokenAddress_),
            shortTokenAddress_
        );
        assertEq(
            leveragedTokenFactory.pair(shortTokenAddress_),
            longTokenAddress_
        );
        assertEq(
            leveragedTokenFactory.isLeveragedToken(longTokenAddress),
            true
        );
        assertEq(
            leveragedTokenFactory.isLeveragedToken(shortTokenAddress),
            true
        );
        assertEq(leveragedTokenFactory.isLeveragedToken(Tokens.UNI), false);
    }

    function testRevertsNoPositionManager() public {
        vm.expectRevert(ILeveragedTokenFactory.NoPositionManager.selector);
        leveragedTokenFactory.createLeveragedTokens(Symbols.BTC, 1.23e18);
    }

    function testRevertsZeroLeverage() public {
        vm.expectRevert(ILeveragedTokenFactory.ZeroLeverage.selector);
        leveragedTokenFactory.createLeveragedTokens(Symbols.UNI, 0);
    }

    function testRevertsMaxLeverage() public {
        vm.expectRevert(ILeveragedTokenFactory.MaxLeverage.selector);
        leveragedTokenFactory.createLeveragedTokens(Symbols.UNI, 101e18);
    }

    function testRevertsTokenExists() public {
        leveragedTokenFactory.createLeveragedTokens(Symbols.UNI, 1.23e18);
        vm.expectRevert(Errors.AlreadyExists.selector);
        leveragedTokenFactory.createLeveragedTokens(Symbols.UNI, 1.23e18);
    }
}
