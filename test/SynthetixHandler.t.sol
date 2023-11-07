// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {SynthetixHandler} from "../src/SynthetixHandler.sol";

import {Contracts} from "../src/libraries/Contracts.sol";
import {Symbols} from "../src/libraries/Symbols.sol";
import {Tokens} from "../src/libraries/Tokens.sol";

contract SynthetixHandlerTest is IntegrationTest {
    SynthetixHandler public synthetixHandler;

    function setUp() public {
        synthetixHandler = new SynthetixHandler(
            address(addressProvider),
            address(Contracts.PERPS_V2_MARKET_DATA)
        );
    }

    function testDepositMargin() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        uint256 balanceBefore = IERC20(Tokens.SUSD).balanceOf(address(this));
        _depositMargin(100e18);
        uint256 balanceAfter = IERC20(Tokens.SUSD).balanceOf(address(this));
        assertEq(balanceBefore - balanceAfter, 100e18);
    }

    function testWithdrawMargin() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        uint256 balanceBefore = IERC20(Tokens.SUSD).balanceOf(address(this));
        _withdrawMargin(50e18);
        uint256 balanceAfter = IERC20(Tokens.SUSD).balanceOf(address(this));
        assertEq(balanceAfter - balanceBefore, 50e18);
    }

    function testCreatePosition() public {
        synthetixHandler.modifyPosition(Symbols.ETH, 0, 0, true);
    }

    function _depositMargin(uint256 amount_) internal {
        (bool success, ) = address(synthetixHandler).delegatecall(
            abi.encodeWithSignature(
                "depositMargin(string,uint256)",
                Symbols.ETH,
                amount_
            )
        );
        assertTrue(success);
    }

    function _withdrawMargin(uint256 amount_) internal {
        (bool success, ) = address(synthetixHandler).delegatecall(
            abi.encodeWithSignature(
                "withdrawMargin(string,uint256)",
                Symbols.ETH,
                amount_
            )
        );
        assertTrue(success);
    }
}
