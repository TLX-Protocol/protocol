// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {SynthetixHandler} from "../src/SynthetixHandler.sol";

import {Contracts} from "../src/libraries/Contracts.sol";
import {Symbols} from "../src/libraries/Symbols.sol";
import {Tokens} from "../src/libraries/Tokens.sol";

contract SynthetixHandlerTest is IntegrationTest {
    using Address for address;

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

    function testSubmitLeverageUpdate() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
    }

    function testHasOpenPosition() public {
        assertFalse(synthetixHandler.hasOpenPosition(Symbols.ETH));
    }

    function testRemainingMargin() public {
        assertEq(synthetixHandler.remainingMargin(Symbols.ETH), 0);
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertEq(synthetixHandler.remainingMargin(Symbols.ETH), 100e18);
    }

    function testTotalValue() public {
        assertEq(synthetixHandler.totalValue(Symbols.ETH), 0);
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertEq(synthetixHandler.totalValue(Symbols.ETH), 100e18);
    }

    function testNotional() public {
        assertEq(synthetixHandler.notionalValue(Symbols.ETH), 0);
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertEq(synthetixHandler.notionalValue(Symbols.ETH), 0);
    }

    function _depositMargin(uint256 amount_) internal {
        address(synthetixHandler).functionDelegateCall(
            abi.encodeWithSignature(
                "depositMargin(string,uint256)",
                Symbols.ETH,
                amount_
            )
        );
    }

    function _withdrawMargin(uint256 amount_) internal {
        address(synthetixHandler).functionDelegateCall(
            abi.encodeWithSignature(
                "withdrawMargin(string,uint256)",
                Symbols.ETH,
                amount_
            )
        );
    }

    function _submitLeverageUpdate(uint256 leverage_, bool isLong_) internal {
        address(synthetixHandler).functionDelegateCall(
            abi.encodeWithSignature(
                "submitLeverageUpdate(string,uint256,bool)",
                Symbols.ETH,
                leverage_,
                isLong_
            )
        );
    }
}
