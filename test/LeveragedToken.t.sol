// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LeveragedToken} from "../src/LeveragedToken.sol";
import {Tokens} from "../src/libraries/Tokens.sol";

contract LeveragedTokenTest is Test {
    LeveragedToken public leveragedToken;

    function setUp() public {
        leveragedToken = new LeveragedToken(
            "UNI 2x Long",
            "UNI2L",
            Tokens.UNI,
            2e18,
            true
        );
    }

    function testInit() public {
        assertEq(leveragedToken.name(), "UNI 2x Long");
        assertEq(leveragedToken.symbol(), "UNI2L");
        assertEq(leveragedToken.decimals(), 18);
        assertEq(leveragedToken.targetAsset(), Tokens.UNI);
        assertEq(leveragedToken.targetLeverage(), 2e18);
        assertTrue(leveragedToken.isLong());
    }
}
