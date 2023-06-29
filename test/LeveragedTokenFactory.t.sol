// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {ILeveragedTokenFactory} from "../src/interfaces/ILeveragedTokenFactory.sol";
import {Tokens} from "../src/libraries/Tokens.sol";
import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";

contract LeveragedTokenleveragedTokenFactoryTest is IntegrationTest {
    function testDeployTokens() public {
        (
            address longTokenAddress_,
            address shortTokenAddress_
        ) = leveragedTokenFactory.createLeveragedTokens(Tokens.UNI, 123);
        ILeveragedToken longToken = ILeveragedToken(longTokenAddress_);
        ILeveragedToken shortToken = ILeveragedToken(shortTokenAddress_);
        assertEq(longToken.name(), "UNI 1.23x Long");
        assertEq(longToken.symbol(), "UNI1.23L");
        assertEq(longToken.decimals(), 18);
        assertEq(longToken.targetAsset(), Tokens.UNI);
        assertEq(longToken.targetLeverage(), 123);
        assertTrue(longToken.isLong());
        assertEq(shortToken.name(), "UNI 1.23x Short");
        assertEq(shortToken.symbol(), "UNI1.23S");
        assertEq(shortToken.decimals(), 18);
        assertEq(shortToken.targetAsset(), Tokens.UNI);
        assertEq(shortToken.targetLeverage(), 123);
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
            Tokens.UNI
        );
        assertEq(allTargetTokens.length, 2);
        assertEq(allTargetTokens[0], longTokenAddress_);
        assertEq(allTargetTokens[1], shortTokenAddress_);
        address[] memory emptyTokens = leveragedTokenFactory.allTokens(
            Tokens.USDC
        );
        assertEq(emptyTokens.length, 0);
        address[] memory longTargetTokens = leveragedTokenFactory.longTokens(
            Tokens.UNI
        );
        assertEq(longTargetTokens.length, 1);
        assertEq(longTargetTokens[0], longTokenAddress_);
        address[] memory shortTargetTokens = leveragedTokenFactory.shortTokens(
            Tokens.UNI
        );
        assertEq(shortTargetTokens.length, 1);
        assertEq(shortTargetTokens[0], shortTokenAddress_);
        address longTokenAddress = leveragedTokenFactory.token(
            Tokens.UNI,
            123,
            true
        );
        assertEq(longTokenAddress, longTokenAddress_);
        address shortTokenAddress = leveragedTokenFactory.token(
            Tokens.UNI,
            123,
            false
        );
        assertEq(shortTokenAddress, shortTokenAddress_);
        assertTrue(leveragedTokenFactory.tokenExists(Tokens.UNI, 123, true));
        assertTrue(leveragedTokenFactory.tokenExists(Tokens.UNI, 123, false));
        assertEq(
            leveragedTokenFactory.pair(longTokenAddress_),
            shortTokenAddress_
        );
        assertEq(
            leveragedTokenFactory.pair(shortTokenAddress_),
            longTokenAddress_
        );
    }

    function testReverts() public {
        // Expect revert
        vm.expectRevert(ILeveragedTokenFactory.ZeroAddress.selector);
        leveragedTokenFactory.createLeveragedTokens(address(0), 123);
        vm.expectRevert(ILeveragedTokenFactory.ZeroLeverage.selector);
        leveragedTokenFactory.createLeveragedTokens(Tokens.UNI, 0);
        vm.expectRevert(ILeveragedTokenFactory.MaxLeverage.selector);
        leveragedTokenFactory.createLeveragedTokens(Tokens.UNI, 1000001);
        leveragedTokenFactory.createLeveragedTokens(Tokens.UNI, 123);
        vm.expectRevert(ILeveragedTokenFactory.TokenExists.selector);
        leveragedTokenFactory.createLeveragedTokens(Tokens.UNI, 123);
    }
}
