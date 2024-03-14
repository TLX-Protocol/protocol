// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Symbols} from "../src/libraries/Symbols.sol";
import {Config} from "../src/libraries/Config.sol";
import {ScaledNumber} from "../src/libraries/ScaledNumber.sol";

import {ISynthetixHandler} from "../src/interfaces/ISynthetixHandler.sol";

contract SynthetixHandlerTest is IntegrationTest {
    using Address for address;
    using ScaledNumber for uint256;

    function testDepositMargin() public {
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        uint256 balanceBefore = IERC20(Config.BASE_ASSET).balanceOf(
            address(this)
        );
        _depositMargin(100e18);
        uint256 balanceAfter = IERC20(Config.BASE_ASSET).balanceOf(
            address(this)
        );
        assertEq(balanceBefore - balanceAfter, 100e18);
    }

    function testWithdrawMargin() public {
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        uint256 balanceBefore = IERC20(Config.BASE_ASSET).balanceOf(
            address(this)
        );
        _withdrawMargin(50e18);
        uint256 balanceAfter = IERC20(Config.BASE_ASSET).balanceOf(
            address(this)
        );
        assertEq(balanceAfter - balanceBefore, 50e18);
    }

    function testSubmitLeverageUpdate() public {
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
    }

    function testExecuteOrder() public {
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
    }

    function testSubmitLeverageUpdateTwice() public {
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
    }

    function testHasPendingLeverageUpdate() public {
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        assertFalse(
            synthetixHandler.hasPendingLeverageUpdate(
                _getMarket(Symbols.ETH),
                address(this)
            )
        );
        _submitLeverageUpdate(2e18, true);
        assertTrue(
            synthetixHandler.hasPendingLeverageUpdate(
                _getMarket(Symbols.ETH),
                address(this)
            )
        );
        _executeOrder();
        assertFalse(
            synthetixHandler.hasPendingLeverageUpdate(
                _getMarket(Symbols.ETH),
                address(this)
            )
        );
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        assertFalse(
            synthetixHandler.hasPendingLeverageUpdate(
                _getMarket(Symbols.ETH),
                address(this)
            )
        );
        _submitLeverageUpdate(2e18, true);
        assertTrue(
            synthetixHandler.hasPendingLeverageUpdate(
                _getMarket(Symbols.ETH),
                address(this)
            )
        );
        _executeOrder();
        assertFalse(
            synthetixHandler.hasPendingLeverageUpdate(
                _getMarket(Symbols.ETH),
                address(this)
            )
        );
    }

    function testLeverageDeviationFactor() public {
        assertEq(
            synthetixHandler.leverageDeviationFactor(
                _getMarket(Symbols.ETH),
                address(this),
                2e18
            ),
            0
        );
        _mintTokensFor(Config.BASE_ASSET, address(this), 1_000e18);
        _depositMargin(1_000e18);
        assertEq(
            synthetixHandler.leverageDeviationFactor(
                _getMarket(Symbols.ETH),
                address(this),
                2e18
            ),
            1e18,
            "after deposit margin"
        );
        _submitLeverageUpdate(2e18, true);
        assertApproxEqRel(
            synthetixHandler.leverageDeviationFactor(
                _getMarket(Symbols.ETH),
                address(this),
                2e18
            ),
            1e18,
            0,
            "leverage factor before execution"
        );
        _executeOrder();
        assertApproxEqAbs(
            synthetixHandler.leverageDeviationFactor(
                _getMarket(Symbols.ETH),
                address(this),
                2e18
            ),
            0,
            0.1e18,
            "leverage factor after execution"
        );
    }

    function testHasOpenPosition() public {
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        assertFalse(
            synthetixHandler.hasOpenPosition(
                _getMarket(Symbols.ETH),
                address(this)
            )
        );
        _executeOrder();
        assertTrue(
            synthetixHandler.hasOpenPosition(
                _getMarket(Symbols.ETH),
                address(this)
            )
        );
    }

    function testTotalValue() public {
        assertEq(
            synthetixHandler.totalValue(_getMarket(Symbols.ETH), address(this)),
            0
        );
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        assertEq(
            synthetixHandler.totalValue(_getMarket(Symbols.ETH), address(this)),
            100e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.totalValue(_getMarket(Symbols.ETH), address(this)),
            100e18,
            0.01e18
        );
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        assertApproxEqRel(
            synthetixHandler.totalValue(_getMarket(Symbols.ETH), address(this)),
            200e18,
            0.01e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.totalValue(_getMarket(Symbols.ETH), address(this)),
            200e18,
            0.01e18
        );
    }

    function testNotional() public {
        assertEq(
            synthetixHandler.notionalValue(
                _getMarket(Symbols.ETH),
                address(this)
            ),
            0
        );
        _mintTokensFor(Config.BASE_ASSET, address(this), 1000e18);
        _depositMargin(1000e18);
        assertEq(
            synthetixHandler.notionalValue(
                _getMarket(Symbols.ETH),
                address(this)
            ),
            0
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.notionalValue(
                _getMarket(Symbols.ETH),
                address(this)
            ),
            1000e18 * 2,
            0.01e18
        );
        _mintTokensFor(Config.BASE_ASSET, address(this), 1000e18);
        _depositMargin(1000e18);
        assertApproxEqRel(
            synthetixHandler.notionalValue(
                _getMarket(Symbols.ETH),
                address(this)
            ),
            1000e18 * 2,
            0.01e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.notionalValue(
                _getMarket(Symbols.ETH),
                address(this)
            ),
            2000e18 * 2,
            0.01e18
        );
    }

    function testLeverage() public {
        _mintTokensFor(Config.BASE_ASSET, address(this), 1000e18);
        _depositMargin(1000e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.leverage(_getMarket(Symbols.ETH), address(this)),
            2e18,
            0.01e18,
            "First leverage check"
        );
        _mintTokensFor(Config.BASE_ASSET, address(this), 1000e18);
        _depositMargin(1000e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.leverage(_getMarket(Symbols.ETH), address(this)),
            2e18,
            0.01e18,
            "Second leverage check"
        );
    }

    function testIsLongTrue() public {
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertTrue(
            synthetixHandler.isLong(_getMarket(Symbols.ETH), address(this))
        );
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertTrue(
            synthetixHandler.isLong(_getMarket(Symbols.ETH), address(this))
        );
    }

    function testIsLongFalse() public {
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, false);
        _executeOrder();
        assertFalse(
            synthetixHandler.isLong(_getMarket(Symbols.ETH), address(this))
        );
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, false);
        _executeOrder();
        assertFalse(
            synthetixHandler.isLong(_getMarket(Symbols.ETH), address(this))
        );
    }

    function testRemainingMargin() public {
        assertEq(
            synthetixHandler.remainingMargin(
                _getMarket(Symbols.ETH),
                address(this)
            ),
            0
        );
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        assertEq(
            synthetixHandler.remainingMargin(
                _getMarket(Symbols.ETH),
                address(this)
            ),
            100e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.remainingMargin(
                _getMarket(Symbols.ETH),
                address(this)
            ),
            100e18,
            0.01e18
        );
        _mintTokensFor(Config.BASE_ASSET, address(this), 100e18);
        _depositMargin(100e18);
        assertApproxEqRel(
            synthetixHandler.remainingMargin(
                _getMarket(Symbols.ETH),
                address(this)
            ),
            200e18,
            0.01e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.remainingMargin(
                _getMarket(Symbols.ETH),
                address(this)
            ),
            200e18,
            0.01e18
        );
    }

    function testIsAssetSupported() public {
        assertTrue(synthetixHandler.isAssetSupported(Symbols.ETH));
        assertFalse(synthetixHandler.isAssetSupported("BABYDOGE"));
    }

    function _getMarket(string memory symbol_) internal view returns (address) {
        return synthetixHandler.market(symbol_);
    }

    function _depositMargin(uint256 amount_) internal {
        address(synthetixHandler).functionDelegateCall(
            abi.encodeWithSelector(
                ISynthetixHandler.depositMargin.selector,
                _getMarket(Symbols.ETH),
                amount_
            )
        );
    }

    function _withdrawMargin(uint256 amount_) internal {
        address(synthetixHandler).functionDelegateCall(
            abi.encodeWithSelector(
                ISynthetixHandler.withdrawMargin.selector,
                _getMarket(Symbols.ETH),
                amount_
            )
        );
    }

    function _submitLeverageUpdate(uint256 leverage_, bool isLong_) internal {
        address(synthetixHandler).functionDelegateCall(
            abi.encodeWithSelector(
                ISynthetixHandler.submitLeverageUpdate.selector,
                _getMarket(Symbols.ETH),
                leverage_,
                isLong_
            )
        );
    }
}
