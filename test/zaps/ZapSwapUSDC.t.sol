// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "../shared/IntegrationTest.sol";

import {ILeveragedToken} from "../../src/interfaces/ILeveragedToken.sol";
// UPDATE: Only using full path here because it's complaining
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Tokens} from "../../src/libraries/Tokens.sol";
import {Symbols} from "../../src/libraries/Symbols.sol";
import {Contracts} from "../../src/libraries/Contracts.sol";
import {Config} from "../../src/libraries/Config.sol";
import {ScaledNumber} from "../../src/libraries/ScaledNumber.sol";

import {ZapSwapUSDC} from "../../src/zaps/ZapSwapUSDC.sol";

contract WrappedZapSwapUSDC is ZapSwapUSDC {
    constructor(
        string memory name_,
        address usdcAddress_,
        address addressProvider_,
        address velodromeRouter_,
        address defaultFactory_
    )
        ZapSwapUSDC(
            name_,
            usdcAddress_,
            addressProvider_,
            velodromeRouter_,
            defaultFactory_
        )
    {}

    function swapUSDCForBaseAsset(
        uint256 amountIn_,
        uint256 minAmountOut_
    ) public {
        return _swapUSDCForBaseAsset(amountIn_, minAmountOut_);
    }

    function swapBaseAssetForUSDC(
        uint256 amountIn_,
        uint256 minAmountOut_
    ) public {
        return _swapBaseAssetForUSDC(amountIn_, minAmountOut_);
    }
}

contract ZapSwapUSDCTest is IntegrationTest {
    using ScaledNumber for uint256;
    ZapSwapUSDC public zapSwapUSDC;
    WrappedZapSwapUSDC public wrappedZapSwapUSDC;
    ILeveragedToken public leveragedToken;
    IERC20 internal constant _USDC = IERC20(Tokens.USDC);
    IERC20 internal constant _SUSD = IERC20(Tokens.SUSD);

    function setUp() public override {
        super.setUp();
        _mintTokensFor(address(_USDC), address(this), 1000e6);
        _mintTokensFor(address(_SUSD), address(this), 1000e18);
        zapSwapUSDC = new ZapSwapUSDC(
            "USDC",
            Tokens.USDC,
            address(addressProvider),
            Contracts.VELODROME_ROUTER,
            Contracts.VELODROME_DEFAULT_FACTORY
        );
        wrappedZapSwapUSDC = new WrappedZapSwapUSDC(
            "USDC",
            Tokens.USDC,
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
        assertEq(zapSwapUSDC.zapAsset(), "USDC");
    }

    function testSimpleMint() public {
        _USDC.approve(address(zapSwapUSDC), 1000e6);
        zapSwapUSDC.mint(address(leveragedToken), 1000e6, 0);
        assertGt(
            leveragedToken.balanceOf(address(this)),
            0,
            "No leveraged token was minted."
        );
        assertApproxEqRel(
            leveragedToken.balanceOf(address(this)),
            1000e18,
            0.01e18,
            "Number of leveraged tokens minted too low"
        );

        uint256 leveragedTokenValue = leveragedToken
            .balanceOf(address(this))
            .mul(leveragedToken.exchangeRate());

        assertApproxEqRel(
            1000e18,
            leveragedTokenValue,
            0.01e18,
            "Value of leveraged token minted does not match amountIn."
        );
    }

    function testMintRevert() public {
        // Mint with 0 USDC
        _USDC.approve(address(zapSwapUSDC), 1000e6);
        assertEq(zapSwapUSDC.mint(address(leveragedToken), 0, 0), 0);
        // Mint with wrong lt address
        vm.expectRevert();
        zapSwapUSDC.mint(address(6), 1000e6, 0);
        // Mint more
        vm.expectRevert();
        zapSwapUSDC.mint(address(leveragedToken), 1200e6, 0);
    }

    function testSimpleRedeem() public {
        // Mint leveraged tokens with baseAsset
        uint256 amountIn = 1000e18;
        _mintTokensFor(address(_SUSD), address(this), amountIn);
        uint256 minLeveragedTokenAmountOut = 1000e18;
        _SUSD.approve(address(leveragedToken), amountIn);
        leveragedToken.mint(amountIn, minLeveragedTokenAmountOut);
        _executeOrder(address(leveragedToken));

        // Verify mint quantities
        assertEq(leveragedToken.balanceOf(address(this)), 1000e18);
        // LT value in baseAsset
        uint256 leveragedTokenValue = leveragedToken
            .balanceOf(address(this))
            .mul(leveragedToken.exchangeRate());
        assertApproxEqRel(
            amountIn,
            leveragedTokenValue,
            0.01e18,
            "Value of leveraged token minted does not match amountIn."
        );

        // Redeem half of the owned leveraged tokens for USDC
        uint256 leverageTokenAmountToRedeem = leveragedToken.balanceOf(
            address(this)
        ) / 2;
        uint256 halfAmountInUSDC = 500e6;
        uint256 minUSDCAmountOut = 490e6;

        leveragedToken.approve(
            address(zapSwapUSDC),
            leverageTokenAmountToRedeem
        );
        uint256 usdcBalanceBeforeRedeem = _USDC.balanceOf(address(this));
        zapSwapUSDC.redeem(
            address(leveragedToken),
            leverageTokenAmountToRedeem,
            minUSDCAmountOut
        );

        uint256 usdcBalanceAfterRedeem = _USDC.balanceOf(address(this)) -
            usdcBalanceBeforeRedeem;

        assertApproxEqRel(
            halfAmountInUSDC,
            usdcBalanceAfterRedeem,
            0.02e18,
            "Didn't receive enough USDC from leveraged token redemption."
        );
    }

    function testRedeemRevert() public {
        // Redeem with wrong address
        mintLeveragedTokenWithUSDC(1000e6);
        _executeOrder(address(leveragedToken));
        vm.expectRevert();
        zapSwapUSDC.redeem(address(5), 900e6, 0);
        // Redeem more than owned
        vm.expectRevert();
        zapSwapUSDC.redeem(address(leveragedToken), 1100e6, 0);
    }

    function testSwapUSDCForBaseAsset() public {
        _USDC.approve(address(wrappedZapSwapUSDC), 1000e6);
        _USDC.transfer(address(wrappedZapSwapUSDC), 1000e6);
        assertEq(_USDC.balanceOf(address(wrappedZapSwapUSDC)), 1000e6);
        wrappedZapSwapUSDC.swapUSDCForBaseAsset(1000e6, 0);
        // USDC is 1e6, and SUSD is 1e18
        assertApproxEqRel(
            1000e18,
            addressProvider.baseAsset().balanceOf(address(wrappedZapSwapUSDC)),
            0.01e18
        );
    }

    function testSwapBaseAssetForUSDC() public {
        _SUSD.approve(address(wrappedZapSwapUSDC), 1000e18);
        _SUSD.transfer(address(wrappedZapSwapUSDC), 1000e18);
        assertEq(_SUSD.balanceOf(address(wrappedZapSwapUSDC)), 1000e18);
        wrappedZapSwapUSDC.swapBaseAssetForUSDC(1000e18, 0);
        // USDC is 1e6, and SUSD is 1e18
        assertApproxEqRel(
            1000e6,
            _USDC.balanceOf(address(wrappedZapSwapUSDC)),
            0.01e18
        );
    }

    function testUserActivity() public {
        userActivity();

        // Verify Alice's leveraged token value
        uint256 aliceLtValue = leveragedToken.balanceOf(alice).mul(
            leveragedToken.exchangeRate()
        );
        assertApproxEqRel(2000e18, aliceLtValue, 0.02e18);

        // Verify Bob's leveraged token value
        uint256 bobLtValue = leveragedToken.balanceOf(bob).mul(
            leveragedToken.exchangeRate()
        );
        assertApproxEqRel(3000e18, bobLtValue, 0.02e18);

        // Verify Bob's USDC holdings
        assertApproxEqAbs(3000e6, _USDC.balanceOf(bob), 0.02e18);
    }

    function mintLeveragedTokenWithUSDC(uint256 amountIn_) public {
        _USDC.approve(address(zapSwapUSDC), amountIn_);
        zapSwapUSDC.mint(address(leveragedToken), amountIn_, 0);
    }

    function userActivity() public {
        // alice mints for 2000 USDC
        // bob mints for 5000 USDC
        // bob redeems 2000 USDC
        uint256 aliceIn = 2000e6;
        uint256 bobIn = 6000e6;

        _mintTokensFor(address(_USDC), alice, aliceIn);
        _mintTokensFor(address(_USDC), bob, bobIn);

        vm.prank(alice);
        _USDC.approve(address(zapSwapUSDC), aliceIn);
        vm.prank(bob);
        _USDC.approve(address(zapSwapUSDC), bobIn);

        vm.prank(alice);
        zapSwapUSDC.mint(address(leveragedToken), aliceIn, 0);
        _executeOrder(address(leveragedToken));
        vm.prank(bob);
        zapSwapUSDC.mint(address(leveragedToken), bobIn, 0);
        _executeOrder(address(leveragedToken));

        // Bob withdraws hald his leveraged tokens
        uint256 bobLeveragedTokenOut = leveragedToken.balanceOf(bob).div(2e18);
        vm.prank(bob);
        leveragedToken.approve(address(zapSwapUSDC), bobLeveragedTokenOut);
        vm.prank(bob);
        zapSwapUSDC.redeem(address(leveragedToken), bobLeveragedTokenOut, 0);
    }
}
