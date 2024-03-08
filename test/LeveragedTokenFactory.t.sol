// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Tokens} from "../src/libraries/Tokens.sol";
import {Errors} from "../src/libraries/Errors.sol";
import {Symbols} from "../src/libraries/Symbols.sol";
import {Config} from "../src/libraries/Config.sol";

import {ILeveragedTokenFactory} from "../src/interfaces/ILeveragedTokenFactory.sol";
import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";

import {TlxOwnable} from "../src/utils/TlxOwnable.sol";

contract LeveragedTokenFactoryTest is IntegrationTest {
    function testDeployTokens() public {
        (
            address longTokenAddress_,
            address shortTokenAddress_
        ) = leveragedTokenFactory.createLeveragedTokens(
                Symbols.UNI,
                1.23e18,
                Config.REBALANCE_THRESHOLD
            );
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

    function testRevertsZeroLeverage() public {
        vm.expectRevert(ILeveragedTokenFactory.ZeroLeverage.selector);
        leveragedTokenFactory.createLeveragedTokens(
            Symbols.UNI,
            0,
            Config.REBALANCE_THRESHOLD
        );
    }

    function testRevertsMaxLeverage() public {
        vm.expectRevert(ILeveragedTokenFactory.MaxLeverage.selector);
        leveragedTokenFactory.createLeveragedTokens(
            Symbols.UNI,
            101e18,
            Config.REBALANCE_THRESHOLD
        );
    }

    function testRevertsTokenExists() public {
        leveragedTokenFactory.createLeveragedTokens(
            Symbols.UNI,
            1.23e18,
            Config.REBALANCE_THRESHOLD
        );
        vm.expectRevert(Errors.AlreadyExists.selector);
        leveragedTokenFactory.createLeveragedTokens(
            Symbols.UNI,
            1.23e18,
            Config.REBALANCE_THRESHOLD
        );
    }

    function testRedeployInactiveToken() public {
        // Creating some leveraged tokens
        (
            address longTokenAddress_,
            address shortTokenAddress_
        ) = leveragedTokenFactory.createLeveragedTokens(
                Symbols.UNI,
                1.23e18,
                Config.REBALANCE_THRESHOLD
            );

        // Testing can only be called by owner
        vm.expectRevert(TlxOwnable.NotOwner.selector);
        vm.prank(alice);
        leveragedTokenFactory.redeployInactiveToken(address(0));

        // Testing has to be a leveraged token
        vm.expectRevert(Errors.NotLeveragedToken.selector);
        leveragedTokenFactory.redeployInactiveToken(Tokens.USDC);

        // Testing has to be inactive
        vm.expectRevert(ILeveragedTokenFactory.NotInactive.selector);
        leveragedTokenFactory.redeployInactiveToken(longTokenAddress_);

        // Testing it works
        vm.mockCall(
            longTokenAddress_,
            abi.encodeWithSelector(ILeveragedToken.isActive.selector),
            abi.encode(false)
        );
        address newToken_ = leveragedTokenFactory.redeployInactiveToken(
            longTokenAddress_
        );

        // Testing the pairs are set correctly
        assertEq(leveragedTokenFactory.pair(newToken_), shortTokenAddress_);
        assertEq(leveragedTokenFactory.pair(shortTokenAddress_), newToken_);

        // Testing the old one is no longer a leveraged token
        assertEq(
            leveragedTokenFactory.isLeveragedToken(longTokenAddress_),
            false
        );

        // Testing you can't do it twice
        vm.expectRevert(Errors.NotLeveragedToken.selector);
        leveragedTokenFactory.redeployInactiveToken(longTokenAddress_);
    }
}
