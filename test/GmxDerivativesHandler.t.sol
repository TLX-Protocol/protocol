// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Contracts} from "../src/libraries/Contracts.sol";
import {Tokens} from "../src/libraries/Tokens.sol";

import {GmxDerivativesHandler} from "../src/GmxDerivativesHandler.sol";

contract GmxDerivativesHandlerTest is IntegrationTest {
    GmxDerivativesHandler public derivativesHandler;

    function setUp() public {
        derivativesHandler = new GmxDerivativesHandler(
            Contracts.GMX_POSITION_ROUTER,
            Contracts.GMX_ROUTER,
            Tokens.USDC
        );
        derivativesHandler.initialize();
    }

    function testDummy() public {
        assertTrue(true);
    }
}
