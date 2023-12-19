// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

// DELETE
import "forge-std/console.sol";

import {IntegrationTest} from "../shared/IntegrationTest.sol";

import {ILeveragedToken} from "../../src/interfaces/ILeveragedToken.sol";
// UPDATE: Only using full path here because it's complaining
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Tokens} from "../../src/libraries/Tokens.sol";
import {Symbols} from "../../src/libraries/Symbols.sol";
import {Contracts} from "../../src/libraries/Contracts.sol";
import {Config} from "../../src/libraries/Config.sol";

import {ZapUSDC} from "../../src/zaps/ZapUSDC.sol";

contract WrappedZapUSDC is ZapUSDC {
    constructor(
        string memory name_,
        address usdcAddress_,
        address susdAddress_,
        address addressProvider_,
        address velodromeRouter_,
        address defaultFactory_
    )
        ZapUSDC(
            name_,
            usdcAddress_,
            susdAddress_,
            addressProvider_,
            velodromeRouter_,
            defaultFactory_
        )
    {}

    function swapUsdcForSusd(
        uint256 amountIn,
        uint256 minAmountOut
    ) public returns (uint256) {
        return _swapUsdcForSusd(amountIn, minAmountOut);
    }
}

contract ZapUSDCTest is IntegrationTest {
    ZapUSDC public zapUSDC;
    WrappedZapUSDC public wrappedZapUSDC;
    ILeveragedToken public leveragedToken;
    IERC20 internal constant _USDC = IERC20(Tokens.USDC);
    IERC20 internal constant _SUSD = IERC20(Tokens.SUSD);

    function setUp() public override {
        super.setUp();
        _mintTokensFor(address(_USDC), address(this), 1000e6);
        zapUSDC = new ZapUSDC(
            "USDC Zap",
            Tokens.USDC,
            Tokens.SUSD,
            address(addressProvider),
            Contracts.VELODROME_ROUTER,
            Contracts.VELODROME_DEFAULT_FACTORY
        );
        wrappedZapUSDC = new WrappedZapUSDC(
            "Wrapped USDC Zap",
            Tokens.USDC,
            Tokens.SUSD,
            address(addressProvider),
            Contracts.VELODROME_ROUTER,
            Contracts.VELODROME_DEFAULT_FACTORY
        );
        (address longTokenAddress_, ) = leveragedTokenFactory
            .createLeveragedTokens(
                Symbols.ETH,
                2e18,
                Config.REBALANCE_THRESHOLD
            );
        leveragedToken = ILeveragedToken(longTokenAddress_);
    }

    function testInit() public {
        assertEq(zapUSDC.name(), "USDC Zap");
    }

    function testMint() public {
        _USDC.approve(address(zapUSDC), 1000e6);
        zapUSDC.mint(address(leveragedToken), 1000e6, 0);
        assertGt(
            leveragedToken.balanceOf(address(this)),
            0,
            "No leveraged token was minted."
        );
        uint256 leveragedTokenValue = leveragedToken.balanceOf(address(this)) /
            leveragedToken.exchangeRate();
        assertApproxEqRel(
            1000,
            leveragedTokenValue,
            0.05e18,
            "Value of leveraged token minted does not match amount in."
        );
    }

    function testMintRevert() public {
        // Test mint with 0 USDC
        _USDC.approve(address(zapUSDC), 1000e6);
        assertEq(zapUSDC.mint(address(leveragedToken), 0, 0), 0);
        // Test mint with wrong lt address
        vm.expectRevert();
        zapUSDC.mint(address(6), 1000e6, 0);
    }

    function testSwapUsdcForSusd() public {
        _USDC.approve(address(wrappedZapUSDC), 1000e6);
        _USDC.transfer(address(wrappedZapUSDC), 1000e6);
        assertEq(_USDC.balanceOf(address(wrappedZapUSDC)), 1000e6);
        wrappedZapUSDC.swapUsdcForSusd(1000e6, 0);
        // USDC is 1e6, and SUSD is 1e18
        assertApproxEqRel(
            1000e18,
            _SUSD.balanceOf(address(wrappedZapUSDC)),
            0.01e18
        );
    }
}
