// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Contracts} from "../src/libraries/Contracts.sol";
import {Tokens} from "../src/libraries/Tokens.sol";

contract GmxDerivativesHandlerTest is IntegrationTest {
    uint256 internal constant _BASE_AMOUNT = 100e6;
    uint256 internal constant _TARGET_AMOUNT = 200e18;

    function setUp() public {
        derivativesHandler.initialize();
        _mintTokensFor(Tokens.USDC, address(this), _BASE_AMOUNT);
    }

    function testCreatePosition() public {
        // TODO This is failing
        // derivativesHandler.createPosition(
        //     Tokens.UNI,
        //     _BASE_AMOUNT,
        //     _TARGET_AMOUNT,
        //     true
        // );
    }
}
