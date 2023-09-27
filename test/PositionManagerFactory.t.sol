// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Tokens} from "../src/libraries/Tokens.sol";

import {IPositionManagerFactory} from "../src/interfaces/IPositionManagerFactory.sol";

contract PositionManagerFactoryTest is IntegrationTest {
    function testInit() public {
        address[] memory positionManagers_ = positionManagerFactory
            .positionManagers();
        assertEq(positionManagers_.length, 0);
        assertEq(
            positionManagerFactory.positionManager(Tokens.UNI),
            address(0)
        );
        assertFalse(positionManagerFactory.isPositionManager(Tokens.UNI));
    }

    function testCreatePositionManager() public {
        positionManagerFactory.createPositionManager(Tokens.UNI);
        address[] memory positionManagers_ = positionManagerFactory
            .positionManagers();
        assertEq(positionManagers_.length, 1);
        assertEq(
            positionManagerFactory.positionManager(Tokens.UNI),
            positionManagers_[0]
        );
        assertTrue(
            positionManagerFactory.isPositionManager(positionManagers_[0])
        );
    }

    function testRevertsWhenAlreadyExists() public {
        positionManagerFactory.createPositionManager(Tokens.UNI);
        vm.expectRevert(IPositionManagerFactory.AlreadyExists.selector);
        positionManagerFactory.createPositionManager(Tokens.UNI);
    }

    function testRevertsWithNoOracle() public {
        vm.expectRevert(IPositionManagerFactory.NoOracle.selector);
        positionManagerFactory.createPositionManager(Tokens.CRV);
    }
}
