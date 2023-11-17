// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {IPerpsV2MarketData} from "../src/interfaces/synthetix/IPerpsV2MarketData.sol";
import {IPerpsV2MarketConsolidated} from "../src/interfaces/synthetix/IPerpsV2MarketConsolidated.sol";

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Contracts} from "../src/libraries/Contracts.sol";
import {Symbols} from "../src/libraries/Symbols.sol";
import {Tokens} from "../src/libraries/Tokens.sol";
import {ScaledNumber} from "../src/libraries/ScaledNumber.sol";

import {Base64} from "../src/testing/Base64.sol";

import "forge-std/console.sol";
import "forge-std/StdJson.sol";

contract SynthetixHandlerTest is IntegrationTest {
    using Address for address;
    using stdJson for string;
    using ScaledNumber for uint256;

    string constant PYTH_URL = "https://xc-mainnet.pyth.network/api/get_vaa";
    string constant PYTH_ID =
        "0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace"; // ETH/USD

    struct PythResponse {
        string vaa;
        uint256 publishTime;
    }

    receive() external payable {}

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
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertApproxEqRel(
            synthetixHandler.totalValue(Symbols.ETH),
            200e18,
            0.01e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.totalValue(Symbols.ETH),
            200e18,
            0.01e18
        );
    }

    function testNotional() public {
        assertEq(synthetixHandler.notionalValue(Symbols.ETH), 0);
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertEq(synthetixHandler.notionalValue(Symbols.ETH), 0);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.notionalValue(Symbols.ETH),
            100e18 * 2,
            0.01e18
        );
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertApproxEqRel(
            synthetixHandler.notionalValue(Symbols.ETH),
            100e18 * 2,
            0.01e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.notionalValue(Symbols.ETH),
            200e18 * 2,
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
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertApproxEqRel(
            synthetixHandler.remainingMargin(Symbols.ETH),
            200e18,
            0.01e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.remainingMargin(Symbols.ETH),
            200e18,
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

    function _executeOrder() internal {
        uint256 currentTime = block.timestamp;
        uint256 searchTime = currentTime + 5;
        string memory vaa = _getVaa(searchTime);
        bytes memory decoded = Base64.decode(vaa);
        bytes memory hexData = abi.encodePacked(decoded);
        bytes[] memory priceUpdateData = new bytes[](1);
        priceUpdateData[0] = hexData;
        _market(Symbols.ETH).executeOffchainDelayedOrder{value: 1 ether}(
            address(this),
            priceUpdateData
        );
    }

    function _getVaa(uint256 publishTime) internal returns (string memory) {
        string memory url = string.concat(
            PYTH_URL,
            "?id=",
            PYTH_ID,
            "&publish_time=",
            Strings.toString(publishTime)
        );
        string[] memory inputs = new string[](3);
        inputs[0] = "curl";
        inputs[1] = url;
        inputs[2] = "-s";
        bytes memory res = vm.ffi(inputs);
        return abi.decode(string(res).parseRaw(".vaa"), (string));
    }

    function _market(
        string memory targetAsset_
    ) internal view returns (IPerpsV2MarketConsolidated) {
        IPerpsV2MarketData.MarketData memory marketData_ = IPerpsV2MarketData(
            Contracts.PERPS_V2_MARKET_DATA
        ).marketDetailsForKey(_key(targetAsset_));
        require(marketData_.market != address(0), "No market");
        return IPerpsV2MarketConsolidated(marketData_.market);
    }

    function _key(string memory targetAsset_) internal pure returns (bytes32) {
        return bytes32(bytes(abi.encodePacked("s", targetAsset_, "PERP")));
    }
}
