// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Contracts} from "../src/libraries/Contracts.sol";
import {Tokens} from "../src/libraries/Tokens.sol";

contract GmxDerivativesHandlerTest is IntegrationTest {
    function setUp() public {
        derivativesHandler.initialize();
    }

    function testCreatePosition() public {}
}
