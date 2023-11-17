// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Symbols} from "../src/libraries/Symbols.sol";
import {Tokens} from "../src/libraries/Tokens.sol";
import {ScaledNumber} from "../src/libraries/ScaledNumber.sol";

import "forge-std/console.sol";

contract SynthetixHandlerTest is IntegrationTest {
    using Address for address;
    using ScaledNumber for uint256;

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

    function testExecuteOrder() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
    }

    function testSubmitLeverageUpdateTwice() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
    }

    function testHasPendingLeverageUpdate() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertFalse(synthetixHandler.hasPendingLeverageUpdate(Symbols.ETH));
        _submitLeverageUpdate(2e18, true);
        assertTrue(synthetixHandler.hasPendingLeverageUpdate(Symbols.ETH));
        _executeOrder();
        assertFalse(synthetixHandler.hasPendingLeverageUpdate(Symbols.ETH));
    }

    function testCancelLeverageUpdate() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        assertTrue(synthetixHandler.hasPendingLeverageUpdate(Symbols.ETH));
        skip(2 minutes);
        _cancelLeverageUpdate();
        assertFalse(synthetixHandler.hasPendingLeverageUpdate(Symbols.ETH));
    }

    function testHasOpenPosition() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        assertFalse(synthetixHandler.hasOpenPosition(Symbols.ETH));
        _executeOrder();
        assertTrue(synthetixHandler.hasOpenPosition(Symbols.ETH));
    }

    function testTotalValue() public {
        assertEq(synthetixHandler.totalValue(Symbols.ETH), 0);
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertEq(synthetixHandler.totalValue(Symbols.ETH), 100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.totalValue(Symbols.ETH),
            100e18,
            0.01e18
        );
    }

    function testNotional() public {
        assertEq(synthetixHandler.notionalValue(Symbols.ETH), 0);
        uint256 amount_ = 100e18;
        _mintTokensFor(Tokens.SUSD, address(this), amount_);
        _depositMargin(100e18);
        assertEq(synthetixHandler.notionalValue(Symbols.ETH), 0);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.notionalValue(Symbols.ETH),
            100e18 * 2,
            0.01e18
        );
    }

    function testLeverage() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.leverage(Symbols.ETH),
            2e18,
            0.01e18
        );
    }

    function testIsLongTrue() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertTrue(synthetixHandler.isLong(Symbols.ETH));
    }

    function testIsLongFalse() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, false);
        _executeOrder();
        assertFalse(synthetixHandler.isLong(Symbols.ETH));
    }

    function testRemainingMargin() public {
        assertEq(synthetixHandler.remainingMargin(Symbols.ETH), 0);
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertEq(synthetixHandler.remainingMargin(Symbols.ETH), 100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.remainingMargin(Symbols.ETH),
            100e18,
            0.01e18
        );
    }

    function testIsAssetSupported() public {
        assertTrue(synthetixHandler.isAssetSupported(Symbols.ETH));
        assertFalse(synthetixHandler.isAssetSupported("BABYDOGE"));
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

    function _cancelLeverageUpdate() internal {
        address(synthetixHandler).functionDelegateCall(
            abi.encodeWithSignature("cancelLeverageUpdate(string)", Symbols.ETH)
        );
    }
}
