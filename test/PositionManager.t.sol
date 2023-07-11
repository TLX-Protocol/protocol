// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Tokens} from "../src/libraries/Tokens.sol";

import {PositionManager} from "../src/PositionManager.sol";

contract PositionManagerTest is IntegrationTest {
    PositionManager public positionManger;

    function setUp() public {
        positionManger = new PositionManager(Tokens.USDC, Tokens.UNI);
    }

    function testInit() public {
        assertEq(positionManger.baseAsset(), Tokens.USDC);
        assertEq(positionManger.targetAsset(), Tokens.UNI);
    }
}
