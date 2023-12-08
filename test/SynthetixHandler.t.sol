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

    // Some notes on why this is commented out below
    // string constant PYTH_URL = "https://hermes.pyth.network/api/get_vaa";
    // string constant PYTH_ID =
    //     "0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace"; // ETH/USD
    string constant VAA =
        "UE5BVQEAAAADuAEAAAADDQBdPXDahGNNr23Wo+CIBkq9kZLHqI667+PA5fraNH918xy+0w/XbhLUvraNuaNEBYsYb5LhiY/2MgEhngj22e03AAMFiZExKBlpCCR0j8/kvO3bvsoQi7pFKiFfIePaw5Rn9nzGWGhl3WjGcEgH9I4nVa7UrnAbRqPMIaXLDLASlk0wAQZjulzaozrgAZrb3iog34sIxRMXbrOhmPmmPwmnBIvUbh4yi6egeUxf5S+95hg7dh8nwiEM0M0tqHvEz821vna7AQjnVJaM3w6iHnSThMkWydx633fhvMuUCRjxURW01stnBAOCBL1WMsGQWXDDHsdrES3MEuiNVYEkhY9K2uAiN+X9AAlOcZBXAU0Jb5izrcVrG8QOYKIWiVVkfq5Jsh/yPED7pV4RyGefKh5SkF95DLNqFZC8HjYMMqSh8gC4J0+bc4K3AQpZSA6i4rbOHZbxSlgoeG/fpeOcJf8aIl6Uv++kK8SM/xNe0FQA4R5jSo+wAfVijjOF2jTWDEX9hO6TJ69Y/WU6AQsbbzxflnBwq4hC5TtFjtusMLEDBlIzp7pYfWByk6MSkCk1YbguZ4/RWBH/X11Z/ETKVFuo3nWXDd2evwJY2EjxAQxlPMZa410JIXlnxIA4H3inO61sBMYWLJxR0ybKn0DtYH3N4ev40QJ+YOVuqAO0sIPqm69M12pxqVhKPlH/+KixAA0/nKdIHaz0SmC2nsFksxa30x8TJD6dR61fyaMdDIS6E03/HhJ8vT9bqPHHcfuLcAOPKGkhfmkWqPFPjhnRKONXAQ4Y+j5vmyD9l52Qn+tagF1TjAKiDVFNcQfBSiK06ThXC3hdJjj7Pt5Usf8SeKrAA6/+pf0RHgzNN728OsF3+z+VAA9+Do9+UOqPwhn/i3GiM1TvGhXDQwadPCwG9N/bhJq/my8eDlKd5sinXGIIE/A1w83wx4Pz1r3faxkWRniOu6zWABHhKHcCh8nLecCQTH8rOGwD6iIH3vM0YhWtpBKiyzkBahEGR1Ewin1v51O6D2QqQAeLDNyhkrW1hNJKLJDFNjpIABKzqVlIGGw6k+c/UUejYxYY9LFYRyYLFlBkZk2IO3l2ywoU1r6lfZlmiNLdsIw6x0loIy1fzfS1GjvRwbRmjjyFAWVzEgsAAAAAABrhAfrtrFhR4yubI7X5QRqMK6xKrj7U3XuBHdGnLqSqcQAAAAABy1tpAUFVV1YAAAAAAAbSX6oAACcQ1Z4XBgUcxMOAKhsGv2fZAZvH7pIBAFUA/2FJGpMREt3xvYFHzRtkE3X3n1glEm1mVICHRjT9Cs4AAAA3IM7epAAAAAAFSGFk////+AAAAABlcxIKAAAAAGVzEgkAAAA3DMMpcAAAAAAFgWxeCiya6yAcnUvKQ6WTHY+hZESCgVoOLtDwnokED5y2b6Eo/RCJ6ls/X/v8suW6/MSSp9FerSPbzooMjgGRNqpKwYnD73KDP9tSHlUYubhmLIQKv5PZhQGXWEDmq7Y23DDpuFo8DRQBF1Kxr1MRzQsQfhBJNI+4j3J1BUAHMGLhlkueL2BRfvVilCZwu92oEu5GL4GtbNyMbsivwthqdUvxmwqmlRQ6xdue3kiLMTXVQa8OxRIkKuhpr4w8sQy4T6DSpv/XeLnwksYn";

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
        assertFalse(
            synthetixHandler.hasPendingLeverageUpdate(
                Symbols.ETH,
                address(this)
            )
        );
        _submitLeverageUpdate(2e18, true);
        assertTrue(
            synthetixHandler.hasPendingLeverageUpdate(
                Symbols.ETH,
                address(this)
            )
        );
        _executeOrder();
        assertFalse(
            synthetixHandler.hasPendingLeverageUpdate(
                Symbols.ETH,
                address(this)
            )
        );
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertFalse(
            synthetixHandler.hasPendingLeverageUpdate(
                Symbols.ETH,
                address(this)
            )
        );
        _submitLeverageUpdate(2e18, true);
        assertTrue(
            synthetixHandler.hasPendingLeverageUpdate(
                Symbols.ETH,
                address(this)
            )
        );
        _executeOrder();
        assertFalse(
            synthetixHandler.hasPendingLeverageUpdate(
                Symbols.ETH,
                address(this)
            )
        );
    }

    function testCancelLeverageUpdate() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        assertTrue(
            synthetixHandler.hasPendingLeverageUpdate(
                Symbols.ETH,
                address(this)
            )
        );
        skip(2 minutes);
        _cancelLeverageUpdate();
        assertFalse(
            synthetixHandler.hasPendingLeverageUpdate(
                Symbols.ETH,
                address(this)
            )
        );
        _submitLeverageUpdate(2e18, true);
        assertTrue(
            synthetixHandler.hasPendingLeverageUpdate(
                Symbols.ETH,
                address(this)
            )
        );
        skip(2 minutes);
        _cancelLeverageUpdate();
        assertFalse(
            synthetixHandler.hasPendingLeverageUpdate(
                Symbols.ETH,
                address(this)
            )
        );
    }

    function testHasOpenPosition() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        assertFalse(
            synthetixHandler.hasOpenPosition(Symbols.ETH, address(this))
        );
        _executeOrder();
        assertTrue(
            synthetixHandler.hasOpenPosition(Symbols.ETH, address(this))
        );
    }

    function testTotalValue() public {
        assertEq(synthetixHandler.totalValue(Symbols.ETH, address(this)), 0);
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertEq(
            synthetixHandler.totalValue(Symbols.ETH, address(this)),
            100e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.totalValue(Symbols.ETH, address(this)),
            100e18,
            0.01e18
        );
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertApproxEqRel(
            synthetixHandler.totalValue(Symbols.ETH, address(this)),
            200e18,
            0.01e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.totalValue(Symbols.ETH, address(this)),
            200e18,
            0.01e18
        );
    }

    function testNotional() public {
        assertEq(synthetixHandler.notionalValue(Symbols.ETH, address(this)), 0);
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertEq(synthetixHandler.notionalValue(Symbols.ETH, address(this)), 0);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.notionalValue(Symbols.ETH, address(this)),
            100e18 * 2,
            0.01e18
        );
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertApproxEqRel(
            synthetixHandler.notionalValue(Symbols.ETH, address(this)),
            100e18 * 2,
            0.01e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.notionalValue(Symbols.ETH, address(this)),
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
            synthetixHandler.leverage(Symbols.ETH, address(this)),
            2e18,
            0.01e18
        );
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.leverage(Symbols.ETH, address(this)),
            2e18,
            0.01e18
        );
    }

    function testIsLongTrue() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertTrue(synthetixHandler.isLong(Symbols.ETH, address(this)));
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertTrue(synthetixHandler.isLong(Symbols.ETH, address(this)));
    }

    function testIsLongFalse() public {
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, false);
        _executeOrder();
        assertFalse(synthetixHandler.isLong(Symbols.ETH, address(this)));
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        _submitLeverageUpdate(2e18, false);
        _executeOrder();
        assertFalse(synthetixHandler.isLong(Symbols.ETH, address(this)));
    }

    function testRemainingMargin() public {
        assertEq(
            synthetixHandler.remainingMargin(Symbols.ETH, address(this)),
            0
        );
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertEq(
            synthetixHandler.remainingMargin(Symbols.ETH, address(this)),
            100e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.remainingMargin(Symbols.ETH, address(this)),
            100e18,
            0.01e18
        );
        _mintTokensFor(Tokens.SUSD, address(this), 100e18);
        _depositMargin(100e18);
        assertApproxEqRel(
            synthetixHandler.remainingMargin(Symbols.ETH, address(this)),
            200e18,
            0.01e18
        );
        _submitLeverageUpdate(2e18, true);
        _executeOrder();
        assertApproxEqRel(
            synthetixHandler.remainingMargin(Symbols.ETH, address(this)),
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

    // We used to use this API logic, allowing us to get it at any timestamp.
    // The endpoint is in the format https://hermes.pyth.network/api/get_vaa?id=0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace&publish_time=1702040074
    // However suddently the API became super flakey, and stopped working. Tried an alternative, and it was even worse
    // Realised that the timestamp is always roughly the same, so we can just hard code the VAA.
    // Although this will break when we update the block number, meaning we have to manually update the VAA again.
    // Not ideal long term, but hopefully we can switch back to the API when it's more stable.
    function _getVaa(uint256 publishTime) internal returns (string memory) {
        // string memory url = string.concat(
        //     PYTH_URL,
        //     "?id=",
        //     PYTH_ID,
        //     "&publish_time=",
        //     Strings.toString(publishTime)
        // );
        // console.log(url);
        // string[] memory inputs = new string[](3);
        // inputs[0] = "curl";
        // inputs[1] = url;
        // inputs[2] = "-s";
        // bytes memory res = vm.ffi(inputs);
        // return abi.decode(string(res).parseRaw(".vaa"), (string));
        return VAA;
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
