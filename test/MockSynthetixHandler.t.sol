// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {AddressKeys} from "../src/libraries/AddressKeys.sol";
import {ScaledNumber} from "../src/libraries/ScaledNumber.sol";
import {Symbols} from "../src/libraries/Symbols.sol";

import {BaseProtocol} from "../src/testing/MockSynthetixHandler.sol";
import {ILeveragedTokenFactory} from "../src/interfaces/ILeveragedTokenFactory.sol";
import {Tokens} from "../src/libraries/Tokens.sol";
import {ILeveragedToken} from "../src/interfaces/ILeveragedToken.sol";
import {ISynthetixHandler} from "../src/interfaces/ISynthetixHandler.sol";

contract MockSynthetixHandlerTest is IntegrationTest {
    using ScaledNumber for uint256;
    using Address for address;

    uint256 internal constant _AMOUNT = 100_000e18;

    function setUp() public {
        addressProvider.updateAddress(AddressKeys.ORACLE, address(mockOracle));
        _mintTokensFor(Tokens.SUSD, address(this), _AMOUNT);
    }

    function testInit() public {
        assertEq(mockSynthetixHandler.hasOpenPosition(Symbols.UNI), false);
        assertEq(
            mockSynthetixHandler.hasOpenPosition(Symbols.UNI, address(this)),
            false
        );
        assertEq(mockSynthetixHandler.totalValue(Symbols.UNI), 0);
        assertEq(
            mockSynthetixHandler.totalValue(Symbols.UNI, address(this)),
            0
        );
        assertEq(mockSynthetixHandler.notionalValue(Symbols.UNI), 0);

        assertEq(
            mockSynthetixHandler.notionalValue(Symbols.UNI, address(this)),
            0
        );
        assertEq(mockSynthetixHandler.remainingMargin(Symbols.UNI), 0);
        assertEq(
            mockSynthetixHandler.remainingMargin(Symbols.UNI, address(this)),
            0
        );
        assertApproxEqAbs(
            mockSynthetixHandler.fillPrice(Symbols.UNI, 1e18),
            5e18,
            4e18
        );
        assertApproxEqAbs(
            mockSynthetixHandler.assetPrice(Symbols.UNI),
            5e18,
            4e18
        );
    }

    function testRevertsWithNoPositionsExist() public {
        vm.expectRevert();
        address(mockSynthetixHandler).functionDelegateCall(
            abi.encodeWithSignature("closePosition()")
        );
    }

    function testCreatePosition() public {
        _createPosition(Symbols.UNI, _AMOUNT, 2e18, true);
        assertEq(
            mockSynthetixHandler.hasOpenPosition(Symbols.UNI),
            true,
            "hasOpenPosition"
        );
        assertEq(
            mockSynthetixHandler.hasOpenPosition(Symbols.UNI, address(this)),
            true,
            "hasOpenPosition, address(this)"
        );
        assertEq(mockSynthetixHandler.leverage(Symbols.UNI), 2e18);
        assertEq(mockSynthetixHandler.isLong(Symbols.UNI), true, "isLong");

        assertEq(mockSynthetixHandler.remainingMargin(Symbols.UNI), _AMOUNT);
        assertEq(mockSynthetixHandler.totalValue(Symbols.UNI), _AMOUNT);
        uint256 assetPrice_ = mockSynthetixHandler.assetPrice(Symbols.UNI);
        assertEq(
            mockSynthetixHandler.notionalValue(Symbols.UNI),
            _AMOUNT.mul(2e18).div(assetPrice_)
        );
    }

    // function testLongProfitNoFee() public {
    //     mockSynthetixHandler.updateFeePercent(0);
    //     _createPosition(Symbols.UNI, _AMOUNT, 2e18, true);
    //     uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
    //     mockOracle.setPrice(Symbols.UNI, uniPrice_ * 2);

    //     assertEq(mockSynthetixHandler.leverage(Symbols.UNI), 2e18);
    //     assertEq(mockSynthetixHandler.isLong(Symbols.UNI), true, "isLong");
    //     assertEq(mockSynthetixHandler.remainingMargin(Symbols.UNI), _AMOUNT);
    //     assertEq(mockSynthetixHandler.totalValue(Symbols.UNI), _AMOUNT * 2);
    //     uint256 assetPrice_ = mockSynthetixHandler.assetPrice(Symbols.UNI);
    //     assertEq(
    //         mockSynthetixHandler.notionalValue(Symbols.UNI),
    //         _AMOUNT.mul(2e18).div(assetPrice_)
    //     );
    // }

    // function testLongProfitFee() public {
    //     uint256 fee_ = 0.1e18;
    //     mockSynthetixHandler.updateFeePercent(fee_);
    //     _createPosition(Symbols.UNI, _AMOUNT, 2e18, true);
    //     uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
    //     mockOracle.setPrice(Symbols.UNI, uniPrice_ * 2);
    //     skip(365 days); // Incurring a year of fees

    //     uint256 expectedDelta_ = _AMOUNT * 2 - (_AMOUNT * 2).mul(fee_);
    //     assertEq(mockSynthetixHandler.leverage(Symbols.UNI), 2e18);
    //     assertEq(mockSynthetixHandler.isLong(Symbols.UNI), true, "isLong");
    //     assertEq(mockSynthetixHandler.remainingMargin(Symbols.UNI), _AMOUNT);
    //     assertEq(
    //         mockSynthetixHandler.totalValue(Symbols.UNI),
    //         _AMOUNT + expectedDelta_
    //     );
    //     uint256 assetPrice_ = mockSynthetixHandler.assetPrice(Symbols.UNI);
    //     assertEq(
    //         mockSynthetixHandler.notionalValue(Symbols.UNI),
    //         _AMOUNT.mul(2e18).div(assetPrice_)
    //     );
    // }

    // function testLongLossNoFee() public {
    //     mockSynthetixHandler.updateFeePercent(0);
    //     _createPosition(Symbols.UNI, _AMOUNT, 2e18, true);
    //     uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
    //     mockOracle.setPrice(Symbols.UNI, (uniPrice_ * 8) / 10);

    //     uint256 expectedDelta_ = (_AMOUNT * 4) / 10;
    //     assertEq(mockSynthetixHandler.leverage(Symbols.UNI), 2e18);
    //     assertEq(mockSynthetixHandler.isLong(Symbols.UNI), true, "isLong");
    //     assertEq(mockSynthetixHandler.remainingMargin(Symbols.UNI), _AMOUNT);
    //     assertEq(
    //         mockSynthetixHandler.totalValue(Symbols.UNI),
    //         _AMOUNT - expectedDelta_
    //     );
    //     uint256 assetPrice_ = mockSynthetixHandler.assetPrice(Symbols.UNI);
    //     assertEq(
    //         mockSynthetixHandler.notionalValue(Symbols.UNI),
    //         _AMOUNT.mul(2e18).div(assetPrice_)
    //     );
    // }

    // function testLongLossFee() public {
    //     uint256 fee_ = 0.05e18;
    //     mockSynthetixHandler.updateFeePercent(fee_);
    //     _createPosition(Symbols.UNI, _AMOUNT, 2e18, true);
    //     skip(365 days); // Incurring a year of fees
    //     uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
    //     mockOracle.setPrice(Symbols.UNI, (uniPrice_ * 8) / 10);

    //     uint256 expectedDelta_ = (_AMOUNT * 4) / 10 + (_AMOUNT * 2).mul(fee_);
    //     assertEq(mockSynthetixHandler.leverage(Symbols.UNI), 2e18);
    //     assertEq(mockSynthetixHandler.isLong(Symbols.UNI), true, "isLong");
    //     assertEq(mockSynthetixHandler.remainingMargin(Symbols.UNI), _AMOUNT);
    //     assertEq(
    //         mockSynthetixHandler.totalValue(Symbols.UNI),
    //         _AMOUNT - expectedDelta_
    //     );
    //     uint256 assetPrice_ = mockSynthetixHandler.assetPrice(Symbols.UNI);
    //     assertEq(
    //         mockSynthetixHandler.notionalValue(Symbols.UNI),
    //         _AMOUNT.mul(2e18).div(assetPrice_)
    //     );
    // }

    // function testShortProfitNoFee() public {
    //     mockSynthetixHandler.updateFeePercent(0);
    //     _createPosition(Symbols.UNI, _AMOUNT, 2e18, false);
    //     uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
    //     mockOracle.setPrice(Symbols.UNI, (uniPrice_ * 8) / 10);

    //     uint256 expectedDelta_ = (_AMOUNT * 4) / 10;
    //     assertEq(mockSynthetixHandler.leverage(Symbols.UNI), 2e18);
    //     assertEq(mockSynthetixHandler.isLong(Symbols.UNI), false, "isLong");
    //     assertEq(mockSynthetixHandler.remainingMargin(Symbols.UNI), _AMOUNT);
    //     assertEq(
    //         mockSynthetixHandler.totalValue(Symbols.UNI),
    //         _AMOUNT + expectedDelta_
    //     );
    //     uint256 assetPrice_ = mockSynthetixHandler.assetPrice(Symbols.UNI);
    //     assertEq(
    //         mockSynthetixHandler.notionalValue(Symbols.UNI),
    //         _AMOUNT.mul(2e18).div(assetPrice_)
    //     );
    // }

    // function testShortProfitFee() public {
    //     mockSynthetixHandler.updateFeePercent(0.1e18);
    //     _createPosition(Symbols.UNI, _AMOUNT, 2e18, false);
    //     skip(365 days); // Incurring a year of fees
    //     uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
    //     mockOracle.setPrice(Symbols.UNI, (uniPrice_ * 8) / 10);

    //     uint256 expectedDelta_ = (_AMOUNT * 4) / 10 - (_AMOUNT * 2).mul(0.1e18);
    //     assertEq(mockSynthetixHandler.leverage(Symbols.UNI), 2e18);
    //     assertEq(mockSynthetixHandler.isLong(Symbols.UNI), false, "isLong");
    //     assertEq(mockSynthetixHandler.remainingMargin(Symbols.UNI), _AMOUNT);
    //     assertEq(
    //         mockSynthetixHandler.totalValue(Symbols.UNI),
    //         _AMOUNT + expectedDelta_
    //     );
    //     uint256 assetPrice_ = mockSynthetixHandler.assetPrice(Symbols.UNI);
    //     assertEq(
    //         mockSynthetixHandler.notionalValue(Symbols.UNI),
    //         _AMOUNT.mul(2e18).div(assetPrice_)
    //     );
    // }

    // function testShortLossNoFee() public {
    //     mockSynthetixHandler.updateFeePercent(0);
    //     _createPosition(Symbols.UNI, _AMOUNT, 2e18, false);
    //     uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
    //     mockOracle.setPrice(Symbols.UNI, (uniPrice_ * 12) / 10);

    //     uint256 expectedDelta_ = (_AMOUNT * 4) / 10;
    //     assertEq(mockSynthetixHandler.leverage(Symbols.UNI), 2e18);
    //     assertEq(mockSynthetixHandler.isLong(Symbols.UNI), false, "isLong");
    //     assertEq(mockSynthetixHandler.remainingMargin(Symbols.UNI), _AMOUNT);
    //     assertEq(
    //         mockSynthetixHandler.totalValue(Symbols.UNI),
    //         _AMOUNT - expectedDelta_
    //     );
    //     uint256 assetPrice_ = mockSynthetixHandler.assetPrice(Symbols.UNI);
    //     assertEq(
    //         mockSynthetixHandler.notionalValue(Symbols.UNI),
    //         _AMOUNT.mul(2e18).div(assetPrice_)
    //     );
    // }

    // function testShortLossFee() public {
    //     mockSynthetixHandler.updateFeePercent(0.1e18);
    //     _createPosition(Symbols.UNI, _AMOUNT, 2e18, false);
    //     skip(365 days); // Incurring a year of fees
    //     uint256 uniPrice_ = mockOracle.getPrice(Symbols.UNI);
    //     mockOracle.setPrice(Symbols.UNI, (uniPrice_ * 12) / 10);

    //     uint256 expectedDelta_ = (_AMOUNT * 4) / 10 + (_AMOUNT * 2).mul(0.1e18);
    //     assertEq(mockSynthetixHandler.leverage(Symbols.UNI), 2e18);
    //     assertEq(mockSynthetixHandler.isLong(Symbols.UNI), false, "isLong");
    //     assertEq(mockSynthetixHandler.remainingMargin(Symbols.UNI), _AMOUNT);
    //     assertEq(
    //         mockSynthetixHandler.totalValue(Symbols.UNI),
    //         _AMOUNT - expectedDelta_
    //     );
    //     uint256 assetPrice_ = mockSynthetixHandler.assetPrice(Symbols.UNI);
    //     assertEq(
    //         mockSynthetixHandler.notionalValue(Symbols.UNI),
    //         _AMOUNT.mul(2e18).div(assetPrice_)
    //     );
    // }

    function _createPosition(
        string memory targetAsset_,
        uint256 baseAmount_,
        uint256 leverage_,
        bool isLong_
    ) internal {
        address(mockSynthetixHandler).functionDelegateCall(
            abi.encodeWithSignature(
                "depositMargin(string,uint256)",
                targetAsset_,
                baseAmount_
            )
        );
        address(mockSynthetixHandler).functionDelegateCall(
            abi.encodeWithSignature(
                "submitLeverageUpdate(string,uint256,bool)",
                targetAsset_,
                leverage_,
                isLong_
            )
        );
    }
}
