// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {AddressKeys} from "../src/libraries/AddressKeys.sol";
import {ScaledNumber} from "../src/libraries/ScaledNumber.sol";
import {Symbols} from "../src/libraries/Symbols.sol";

import {ILeveragedTokenFactory} from "../src/interfaces/ILeveragedTokenFactory.sol";
import {Tokens} from "../src/libraries/Tokens.sol";
import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";
import {IDerivativesHandler} from "../src/interfaces/IDerivativesHandler.sol";

contract MockDerivativesHandlerTest is IntegrationTest {
    using ScaledNumber for uint256;
    using Address for address;

    uint256 internal constant _AMOUNT = 100_000e18;

    function setUp() public {
        addressProvider.updateAddress(AddressKeys.ORACLE, address(mockOracle));
        _mintTokensFor(Tokens.SUSD, address(this), _AMOUNT);
        IERC20(Tokens.SUSD).approve(
            mockDerivativesHandler.approveAddress(),
            type(uint256).max
        );
    }

    function testInit() public {
        assertEq(mockDerivativesHandler.hasPosition(), false);
    }

    function testRevertsWithNoPositionsExist() public {
        vm.expectRevert(IDerivativesHandler.NoPositionExists.selector);
        address(mockDerivativesHandler).functionDelegateCall(
            abi.encodeWithSignature("closePosition()")
        );
    }

    function testCreatePosition() public {
        _createPosition(Tokens.SUSD, Symbols.UNI, _AMOUNT, 2e18, true);
        assertEq(mockDerivativesHandler.hasPosition(), true, "hasPosition");
        IDerivativesHandler.Position memory position_ = mockDerivativesHandler
            .position();
        assertEq(position_.baseToken, Tokens.SUSD);
        assertEq(position_.targetAsset, Symbols.UNI);
        assertEq(position_.baseAmount, _AMOUNT);
        assertEq(position_.leverage, 2e18);
        assertEq(position_.isLong, true, "isLong");
        assertEq(position_.hasProfit, false, "hasProfit");
        assertEq(position_.delta, 0);
    }

    function testLongProfitNoFee() public {
        mockDerivativesHandler.updateFeePercent(0);
        _createPosition(Tokens.SUSD, Symbols.UNI, _AMOUNT, 2e18, true);
        uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
        mockOracle.setPrice(Symbols.UNI, uniPrice_ * 2);
        IDerivativesHandler.Position memory position_ = mockDerivativesHandler
            .position();
        assertEq(position_.baseAmount, _AMOUNT);
        assertEq(position_.leverage, 2e18);
        assertEq(position_.isLong, true, "isLong");
        assertEq(position_.hasProfit, true, "hasProfit");
        assertEq(position_.delta, _AMOUNT * 2);

        bytes memory owedData_ = address(mockDerivativesHandler)
            .functionDelegateCall(abi.encodeWithSignature("closePosition()"));
        uint256 owed_ = abi.decode(owedData_, (uint256));

        assertEq(owed_, _AMOUNT * 3);
        assertEq(mockDerivativesHandler.hasPosition(), false, "hasPosition");
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(this)), _AMOUNT * 3);
    }

    function testLongProfitFee() public {
        uint256 fee_ = 0.1e18;
        mockDerivativesHandler.updateFeePercent(fee_);
        _createPosition(Tokens.SUSD, Symbols.UNI, _AMOUNT, 2e18, true);
        uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
        mockOracle.setPrice(Symbols.UNI, uniPrice_ * 2);
        skip(365 days); // Incurring a year of fees
        IDerivativesHandler.Position memory position_ = mockDerivativesHandler
            .position();
        assertEq(position_.baseAmount, _AMOUNT);
        assertEq(position_.leverage, 2e18);
        assertEq(position_.isLong, true, "isLong");
        assertEq(position_.hasProfit, true, "hasProfit");
        uint256 expectedDelta_ = _AMOUNT * 2 - (_AMOUNT * 2).mul(fee_);
        assertEq(position_.delta, expectedDelta_, "delta");

        bytes memory owedData_ = address(mockDerivativesHandler)
            .functionDelegateCall(abi.encodeWithSignature("closePosition()"));
        uint256 owed_ = abi.decode(owedData_, (uint256));
        uint256 expected_ = _AMOUNT + expectedDelta_;
        assertEq(owed_, expected_, "owed");
        assertEq(mockDerivativesHandler.hasPosition(), false, "hasPosition");
        assertEq(
            IERC20(Tokens.SUSD).balanceOf(address(this)),
            expected_,
            "gained"
        );
    }

    function testLongLossNoFee() public {
        mockDerivativesHandler.updateFeePercent(0);
        _createPosition(Tokens.SUSD, Symbols.UNI, _AMOUNT, 2e18, true);
        uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
        mockOracle.setPrice(Symbols.UNI, (uniPrice_ * 8) / 10);
        IDerivativesHandler.Position memory position_ = mockDerivativesHandler
            .position();
        assertEq(position_.baseAmount, _AMOUNT);
        assertEq(position_.leverage, 2e18);
        assertEq(position_.isLong, true, "isLong");
        assertEq(position_.hasProfit, false, "hasProfit");
        uint256 expectedDelta_ = (_AMOUNT * 4) / 10;
        assertEq(position_.delta, expectedDelta_);

        bytes memory owedData_ = address(mockDerivativesHandler)
            .functionDelegateCall(abi.encodeWithSignature("closePosition()"));
        uint256 owed_ = abi.decode(owedData_, (uint256));

        uint256 expected_ = _AMOUNT - expectedDelta_;
        assertEq(owed_, expected_);
        assertEq(mockDerivativesHandler.hasPosition(), false, "hasPosition");
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(this)), expected_);
    }

    function testLongLossFee() public {
        uint256 fee_ = 0.05e18;
        mockDerivativesHandler.updateFeePercent(fee_);
        _createPosition(Tokens.SUSD, Symbols.UNI, _AMOUNT, 2e18, true);
        skip(365 days); // Incurring a year of fees
        uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
        mockOracle.setPrice(Symbols.UNI, (uniPrice_ * 8) / 10);
        IDerivativesHandler.Position memory position_ = mockDerivativesHandler
            .position();
        assertEq(position_.baseAmount, _AMOUNT);
        assertEq(position_.leverage, 2e18);
        assertEq(position_.isLong, true, "isLong");
        assertEq(position_.hasProfit, false, "hasProfit");
        uint256 expectedDelta_ = (_AMOUNT * 4) / 10 + (_AMOUNT * 2).mul(fee_);
        assertEq(position_.delta, expectedDelta_);

        bytes memory owedData_ = address(mockDerivativesHandler)
            .functionDelegateCall(abi.encodeWithSignature("closePosition()"));
        uint256 owed_ = abi.decode(owedData_, (uint256));

        uint256 expected_ = _AMOUNT - expectedDelta_;
        assertEq(owed_, expected_);
        assertEq(mockDerivativesHandler.hasPosition(), false, "hasPosition");
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(this)), expected_);
    }

    function testShortProfitNoFee() public {
        mockDerivativesHandler.updateFeePercent(0);
        _createPosition(Tokens.SUSD, Symbols.UNI, _AMOUNT, 2e18, false);
        uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
        mockOracle.setPrice(Symbols.UNI, (uniPrice_ * 8) / 10);
        IDerivativesHandler.Position memory position_ = mockDerivativesHandler
            .position();
        assertEq(position_.baseAmount, _AMOUNT);
        assertEq(position_.leverage, 2e18);
        assertEq(position_.isLong, false, "isLong");
        assertEq(position_.hasProfit, true, "hasProfit");
        uint256 expectedDelta_ = (_AMOUNT * 4) / 10;
        assertEq(position_.delta, expectedDelta_);

        bytes memory owedData_ = address(mockDerivativesHandler)
            .functionDelegateCall(abi.encodeWithSignature("closePosition()"));
        uint256 owed_ = abi.decode(owedData_, (uint256));

        uint256 expected_ = _AMOUNT + expectedDelta_;
        assertEq(owed_, expected_);
        assertEq(mockDerivativesHandler.hasPosition(), false, "hasPosition");
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(this)), expected_);
    }

    function testShortProfitFee() public {
        mockDerivativesHandler.updateFeePercent(0.1e18);
        _createPosition(Tokens.SUSD, Symbols.UNI, _AMOUNT, 2e18, false);
        skip(365 days); // Incurring a year of fees
        uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
        mockOracle.setPrice(Symbols.UNI, (uniPrice_ * 8) / 10);
        IDerivativesHandler.Position memory position_ = mockDerivativesHandler
            .position();
        assertEq(position_.baseAmount, _AMOUNT);
        assertEq(position_.leverage, 2e18);
        assertEq(position_.isLong, false, "isLong");
        assertEq(position_.hasProfit, true, "hasProfit");
        uint256 expectedDelta_ = (_AMOUNT * 4) / 10 - (_AMOUNT * 2).mul(0.1e18);
        assertEq(position_.delta, expectedDelta_);

        bytes memory owedData_ = address(mockDerivativesHandler)
            .functionDelegateCall(abi.encodeWithSignature("closePosition()"));
        uint256 owed_ = abi.decode(owedData_, (uint256));

        uint256 expected_ = _AMOUNT + expectedDelta_;
        assertEq(owed_, expected_);
        assertEq(mockDerivativesHandler.hasPosition(), false, "hasPosition");
        assertEq(IERC20(Tokens.SUSD).balanceOf(address(this)), expected_);
    }

    function testShortLossNoFee() public {
        mockDerivativesHandler.updateFeePercent(0);
        _createPosition(Tokens.SUSD, Symbols.UNI, _AMOUNT, 2e18, false);
        uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
        mockOracle.setPrice(Symbols.UNI, (uniPrice_ * 12) / 10);
        IDerivativesHandler.Position memory position_ = mockDerivativesHandler
            .position();
        assertEq(position_.baseAmount, _AMOUNT);
        assertEq(position_.leverage, 2e18);
        assertEq(position_.isLong, false, "isLong");
        assertEq(position_.hasProfit, false, "hasProfit");
        uint256 expectedDelta_ = (_AMOUNT * 4) / 10;
        assertApproxEqAbs(position_.delta, expectedDelta_, 1e18, "delta");

        bytes memory owedData_ = address(mockDerivativesHandler)
            .functionDelegateCall(abi.encodeWithSignature("closePosition()"));
        uint256 owed_ = abi.decode(owedData_, (uint256));

        uint256 expected_ = _AMOUNT - expectedDelta_;
        assertApproxEqAbs(owed_, expected_, 1e18, "owed");
        assertEq(mockDerivativesHandler.hasPosition(), false, "hasPosition");
        assertApproxEqAbs(
            IERC20(Tokens.SUSD).balanceOf(address(this)),
            expected_,
            1e18,
            "gained"
        );
    }

    function testShortLossFee() public {
        mockDerivativesHandler.updateFeePercent(0.1e18);
        _createPosition(Tokens.SUSD, Symbols.UNI, _AMOUNT, 2e18, false);
        skip(365 days); // Incurring a year of fees
        uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
        mockOracle.setPrice(Symbols.UNI, (uniPrice_ * 12) / 10);
        IDerivativesHandler.Position memory position_ = mockDerivativesHandler
            .position();
        assertEq(position_.baseAmount, _AMOUNT, "baseAmount");
        assertEq(position_.leverage, 2e18, "leverage");
        assertEq(position_.isLong, false, "isLong");
        assertEq(position_.hasProfit, false, "hasProfit");
        uint256 expectedDelta_ = (_AMOUNT * 4) / 10 + (_AMOUNT * 2).mul(0.1e18);
        assertApproxEqAbs(position_.delta, expectedDelta_, 1e18, "delta");

        bytes memory owedData_ = address(mockDerivativesHandler)
            .functionDelegateCall(abi.encodeWithSignature("closePosition()"));
        uint256 owed_ = abi.decode(owedData_, (uint256));

        uint256 expected_ = _AMOUNT - expectedDelta_;
        assertApproxEqAbs(owed_, expected_, 1e18, "owed");
        assertEq(mockDerivativesHandler.hasPosition(), false, "hasPosition");
        assertApproxEqAbs(
            IERC20(Tokens.SUSD).balanceOf(address(this)),
            expected_,
            1e18,
            "gained"
        );
    }

    function _createPosition(
        address baseToken_,
        string memory targetAsset_,
        uint256 baseAmount_,
        uint256 leverage_,
        bool isLong_
    ) internal {
        address(mockDerivativesHandler).functionDelegateCall(
            abi.encodeWithSignature(
                "createPosition(address,string,uint256,uint256,bool)",
                baseToken_,
                targetAsset_,
                baseAmount_,
                leverage_,
                isLong_
            )
        );
    }
}
