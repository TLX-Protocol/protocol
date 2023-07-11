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
            Tokens.USDC,
            Tokens.UNI,
            2e18,
            true,
            address(this)
        );
    }

    function testInit() public {
        assertEq(leveragedToken.name(), "UNI 2x Long");
        assertEq(leveragedToken.symbol(), "UNI2L");
        assertEq(leveragedToken.decimals(), 18);
        assertEq(leveragedToken.baseAsset(), Tokens.USDC);
        assertEq(leveragedToken.targetAsset(), Tokens.UNI);
        assertEq(leveragedToken.targetLeverage(), 2e18);
        assertTrue(leveragedToken.isLong());
    }

    function testMintAndBurn() public {
        leveragedToken.mint(address(this), 100e18);
        assertEq(leveragedToken.totalSupply(), 100e18);
        assertEq(leveragedToken.balanceOf(address(this)), 100e18);

        leveragedToken.burn(address(this), 70e18);
        assertEq(leveragedToken.totalSupply(), 30e18);
        assertEq(leveragedToken.balanceOf(address(this)), 30e18);
    }
}
