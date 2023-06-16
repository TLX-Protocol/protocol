// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Factory} from "../src/Factory.sol";
import {IFactory} from "../src/interfaces/IFactory.sol";
import {Tokens} from "../src/libraries/Tokens.sol";
import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";

contract FactoryTest is IntegrationTest {
    Factory public factory;

    function setUp() public {
        factory = new Factory();
    }

    function testDeployTokens() public {
        (address longTokenAddress_, address shortTokenAddress_) = factory
            .createLeveragedTokens(Tokens.UNI, 123);
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
        address[] memory tokens = factory.allTokens();
        assertEq(tokens.length, 2);
        assertEq(tokens[0], longTokenAddress_);
        assertEq(tokens[1], shortTokenAddress_);
        address[] memory longTokens = factory.longTokens();
        assertEq(longTokens.length, 1);
        assertEq(longTokens[0], longTokenAddress_);
        address[] memory shortTokens = factory.shortTokens();
        assertEq(shortTokens.length, 1);
        assertEq(shortTokens[0], shortTokenAddress_);
        address longTokenAddress = factory.getToken(Tokens.UNI, 123, true);
        assertEq(longTokenAddress, longTokenAddress_);
        address shortTokenAddress = factory.getToken(Tokens.UNI, 123, false);
        assertEq(shortTokenAddress, shortTokenAddress_);
        assertTrue(factory.tokenExists(Tokens.UNI, 123, true));
        assertTrue(factory.tokenExists(Tokens.UNI, 123, false));
        assertEq(factory.pair(longTokenAddress_), shortTokenAddress_);
        assertEq(factory.pair(shortTokenAddress_), longTokenAddress_);
    }

    function testReverts() public {
        // Expect revert
        vm.expectRevert(IFactory.ZeroAddress.selector);
        factory.createLeveragedTokens(address(0), 123);
        vm.expectRevert(IFactory.ZeroLeverage.selector);
        factory.createLeveragedTokens(Tokens.UNI, 0);
        vm.expectRevert(IFactory.MaxLeverage.selector);
        factory.createLeveragedTokens(Tokens.UNI, 1000001);
        factory.createLeveragedTokens(Tokens.UNI, 123);
        vm.expectRevert(IFactory.TokenExists.selector);
        factory.createLeveragedTokens(Tokens.UNI, 123);
    }
}
