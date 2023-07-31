// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {AddressKeys} from "../src/libraries/AddressKeys.sol";
import {ScaledNumber} from "../src/libraries/ScaledNumber.sol";

import {ILeveragedTokenFactory} from "../src/interfaces/ILeveragedTokenFactory.sol";
import {Tokens} from "../src/libraries/Tokens.sol";
import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";
import {IDerivativesHandler} from "../src/interfaces/IDerivativesHandler.sol";

contract MockDerivativesHandlerTest is IntegrationTest {
    using ScaledNumber for uint256;

    uint256 internal constant _AMOUNT = 100_000e6;

    function setUp() public {
        addressProvider.updateAddress(AddressKeys.ORACLE, address(mockOracle));
        _mintTokensFor(Tokens.USDC, address(this), _AMOUNT);
        IERC20(Tokens.USDC).approve(
            address(mockDerivativesHandler),
            type(uint256).max
        );
    }

    function testInit() public {
        assertEq(mockDerivativesHandler.hasPosition(), false);
        vm.expectRevert(IDerivativesHandler.NoPositionExists.selector);
        mockDerivativesHandler.closePosition();
    }

    function testCreatePosition() public {
        mockDerivativesHandler.createPosition(
            Tokens.USDC,
            Tokens.UNI,
            _AMOUNT,
            2e18,
            true
        );
        assertEq(mockDerivativesHandler.hasPosition(), true, "hasPosition");
        IDerivativesHandler.Position memory position_ = mockDerivativesHandler
            .position();
        assertEq(position_.baseToken, Tokens.USDC);
        assertEq(position_.targetToken, Tokens.UNI);
        assertEq(position_.baseAmount, _AMOUNT);
        assertEq(position_.leverage, 2e18);
        assertEq(position_.isLong, true, "isLong");
        assertEq(position_.hasProfit, false, "hasProfit");
        assertEq(position_.delta, 0);
    }

    function testLongProfitNoFee() public {
        mockDerivativesHandler.updateFeePercent(0);
        mockDerivativesHandler.createPosition(
            Tokens.USDC,
            Tokens.UNI,
            _AMOUNT,
            2e18,
            true
        );
        uint256 uniPrice_ = mockOracle.getUsdPrice(Tokens.UNI);
        mockOracle.setPrice(Tokens.UNI, uniPrice_ * 2);
        IDerivativesHandler.Position memory position_ = mockDerivativesHandler
            .position();
        assertEq(position_.baseAmount, _AMOUNT);
        assertEq(position_.leverage, 2e18);
        assertEq(position_.isLong, true, "isLong");
        assertEq(position_.hasProfit, true, "hasProfit");
        assertEq(position_.delta, _AMOUNT * 2);

        uint256 owed_ = mockDerivativesHandler.closePosition();

        assertEq(owed_, _AMOUNT * 3);
        assertEq(mockDerivativesHandler.hasPosition(), false, "hasPosition");
        assertEq(IERC20(Tokens.USDC).balanceOf(address(this)), _AMOUNT * 3);
    }

    function testLongProfitFee() public {
        uint256 fee_ = 0.1e18;
        mockDerivativesHandler.updateFeePercent(fee_);
        mockDerivativesHandler.createPosition(
            Tokens.USDC,
            Tokens.UNI,
            _AMOUNT,
            2e18,
            true
        );
        uint256 uniPrice_ = mockOracle.getUsdPrice(Tokens.UNI);
        mockOracle.setPrice(Tokens.UNI, uniPrice_ * 2);
        skip(365 days); // Incurring a year of fees
        IDerivativesHandler.Position memory position_ = mockDerivativesHandler
            .position();
        assertEq(position_.baseAmount, _AMOUNT);
        assertEq(position_.leverage, 2e18);
        assertEq(position_.isLong, true, "isLong");
        assertEq(position_.hasProfit, true, "hasProfit");
        uint256 expectedDelta_ = _AMOUNT * 2 - (_AMOUNT * 2).mul(fee_);
        assertEq(position_.delta, expectedDelta_, "delta");

        uint256 owed_ = mockDerivativesHandler.closePosition();
        uint256 expected_ = _AMOUNT + expectedDelta_;
        assertEq(owed_, expected_, "owed");
        assertEq(mockDerivativesHandler.hasPosition(), false, "hasPosition");
        assertEq(
            IERC20(Tokens.USDC).balanceOf(address(this)),
            expected_,
            "gained"
        );
    }
}
