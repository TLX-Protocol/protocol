// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "../shared/IntegrationTest.sol";

import {ILeveragedToken} from "../../src/interfaces/ILeveragedToken.sol";
import {IZapSwap} from "../../src/interfaces/IZapSwap.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Tokens} from "../../src/libraries/Tokens.sol";
import {Symbols} from "../../src/libraries/Symbols.sol";
import {Contracts} from "../../src/libraries/Contracts.sol";
import {Config} from "../../src/libraries/Config.sol";
import {ScaledNumber} from "../../src/libraries/ScaledNumber.sol";

import {ZapSwapDirect} from "../../src/zaps/ZapSwapDirect.sol";
import {ZapSwapIndirect} from "../../src/zaps/ZapSwapIndirect.sol";

contract WrappedZapSwapDirect is ZapSwapDirect {
    constructor(
        address zapAsset_,
        address addressProvider_,
        address velodromeRouter_,
        address defaultFactory_
    )
        ZapSwapDirect(
            zapAsset_,
            addressProvider_,
            velodromeRouter_,
            defaultFactory_
        )
    {}

    function swapZapAssetForBaseAsset(uint256 amountIn_) public {
        return _swapZapAssetForBaseAsset(amountIn_);
    }

    function swapBaseAssetForZapAsset(uint256 amountIn_) public {
        return _swapBaseAssetForZapAsset(amountIn_);
    }
}

contract WrappedZapSwapIndirect is ZapSwapIndirect {
    constructor(
        address zapAsset_,
        address addressProvider_,
        address velodromeRouter_,
        address defaultFactory_,
        address bridgeAsset_
    )
        ZapSwapIndirect(
            zapAsset_,
            addressProvider_,
            velodromeRouter_,
            defaultFactory_,
            bridgeAsset_
        )
    {}

    function swapZapAssetForBaseAsset(uint256 amountIn_) public {
        return _swapZapAssetForBaseAsset(amountIn_);
    }

    function swapBaseAssetForZapAsset(uint256 amountIn_) public {
        return _swapBaseAssetForZapAsset(amountIn_);
    }
}

contract ZapSwapUSDCTest is IntegrationTest {
    using ScaledNumber for uint256;

    // ZapSwap contracts as deployed
    ZapSwapDirect public zapSwapUSDC;
    ZapSwapIndirect public zapSwapUSDT;
    ZapSwapIndirect public zapSwapDAI;

    // Wrapped ZapSwaps for testing internal swap functions
    WrappedZapSwapDirect public wrappedZapSwapUSDC;
    WrappedZapSwapIndirect public wrappedZapSwapUSDT;
    WrappedZapSwapIndirect public wrappedZapSwapDAI;

    ILeveragedToken public leveragedToken;
    IERC20 internal constant _USDC = IERC20(Tokens.USDC);
    IERC20 internal constant _SUSD = IERC20(Tokens.SUSD);
    IERC20 internal constant _USDT = IERC20(Tokens.USDT);
    IERC20 internal constant _DAI = IERC20(Tokens.DAI);

    function setUp() public override {
        super.setUp();

        zapSwapUSDC = new ZapSwapDirect(
            Tokens.USDC, // zapAsset
            address(addressProvider),
            Contracts.VELODROME_ROUTER,
            Contracts.VELODROME_DEFAULT_FACTORY
        );
        zapSwapUSDT = new ZapSwapIndirect(
            Tokens.USDT, // zapAsset
            address(addressProvider),
            Contracts.VELODROME_ROUTER,
            Contracts.VELODROME_DEFAULT_FACTORY,
            Tokens.USDC // bridgeAsset
        );
        zapSwapDAI = new ZapSwapIndirect(
            Tokens.DAI, // zapAsset
            address(addressProvider),
            Contracts.VELODROME_ROUTER,
            Contracts.VELODROME_DEFAULT_FACTORY,
            Tokens.USDC // bridgeAsset
        );
        wrappedZapSwapUSDC = new WrappedZapSwapDirect(
            Tokens.USDC,
            address(addressProvider),
            Contracts.VELODROME_ROUTER,
            Contracts.VELODROME_DEFAULT_FACTORY
        );
        wrappedZapSwapUSDT = new WrappedZapSwapIndirect(
            Tokens.USDT,
            address(addressProvider),
            Contracts.VELODROME_ROUTER,
            Contracts.VELODROME_DEFAULT_FACTORY,
            Tokens.USDC
        );
        wrappedZapSwapDAI = new WrappedZapSwapIndirect(
            Tokens.DAI,
            address(addressProvider),
            Contracts.VELODROME_ROUTER,
            Contracts.VELODROME_DEFAULT_FACTORY,
            Tokens.USDC
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
        assertEq(zapSwapUSDC.zapAsset(), Tokens.USDC);
        assertEq(zapSwapUSDT.zapAsset(), Tokens.USDT);
        assertEq(zapSwapDAI.zapAsset(), Tokens.DAI);
    }

    function testSimpleMintWithUSDC() public {
        simpleMint(zapSwapUSDC, 1000e6, 1000e18);
    }

    function testSimpleMintWithUSDT() public {
        simpleMint(zapSwapUSDT, 1000e6, 1000e18);
    }

    function testSimpleMintWithDAI() public {
        simpleMint(zapSwapDAI, 1000e18, 1000e18);
    }

    function simpleMint(
        IZapSwap zapSwap,
        uint256 amountIn,
        uint256 expectedAmountOut
    ) public {
        IERC20 zapAsset = IERC20(zapSwap.zapAsset());
        _mintTokensFor(address(zapAsset), address(this), amountIn);
        zapAsset.approve(address(zapSwap), amountIn);
        zapSwap.mint(address(leveragedToken), amountIn, 0);
        assertGt(
            leveragedToken.balanceOf(address(this)),
            0,
            "No leveraged token was minted."
        );
        assertApproxEqRel(
            leveragedToken.balanceOf(address(this)),
            expectedAmountOut,
            0.01e18,
            "Number of leveraged tokens minted too low"
        );

        uint256 leveragedTokenValue = leveragedToken
            .balanceOf(address(this))
            .mul(leveragedToken.exchangeRate());

        assertApproxEqRel(
            expectedAmountOut,
            leveragedTokenValue,
            0.01e18,
            "Value of leveraged token minted does not match amountIn."
        );
    }

    function testMintRevertDirectZapSwap() public {
        mintRevert(zapSwapUSDC, 1000e6, 1000e18);
    }

    function testMintRevertIndirectZapSwap() public {
        mintRevert(zapSwapDAI, 1000e18, 1000e18);
    }

    function mintRevert(
        IZapSwap zapSwap,
        uint256 amountIn,
        uint256 expectedAmountOut
    ) public {
        IERC20 zapAsset = IERC20(zapSwap.zapAsset());
        _mintTokensFor(address(zapAsset), address(this), amountIn);
        zapAsset.approve(address(zapSwap), amountIn);

        // Mint with 0 USDC
        assertEq(zapSwap.mint(address(leveragedToken), 0, 0), 0);

        // Mint with wrong lt address
        vm.expectRevert();
        zapSwap.mint(address(6), amountIn, 0);

        // Mint with higher amountIn
        vm.expectRevert();
        zapSwap.mint(address(leveragedToken), amountIn * 2, 0);

        // Mint with higher minAmountOut
        vm.expectRevert();
        zapSwap.mint(address(leveragedToken), amountIn, expectedAmountOut * 2);
    }

    function testSimpleRedeemWithUSDC() public {
        simpleRedeem(zapSwapUSDC, 1000e18, 1000e6);
    }

    function testSimpleRedeemWithUSDT() public {
        simpleRedeem(zapSwapUSDT, 1000e18, 1000e6);
    }

    function testSimpleRedeemWithDAI() public {
        simpleRedeem(zapSwapDAI, 1000e18, 1000e18);
    }

    function simpleRedeem(
        IZapSwap zapSwap,
        uint256 baseAssetAmountIn,
        uint256 zapAssetAmountOut
    ) public {
        // Mint leveraged tokens with baseAsset and without using the zap
        _mintTokensFor(address(_SUSD), address(this), baseAssetAmountIn);
        _SUSD.approve(address(leveragedToken), baseAssetAmountIn);
        leveragedToken.mint(baseAssetAmountIn, 0);
        _executeOrder(address(leveragedToken));
        assertEq(leveragedToken.balanceOf(address(this)), 1000e18);

        // Determine value of LTs minted in terms of baseAsset
        uint256 leveragedTokenValue = leveragedToken
            .balanceOf(address(this))
            .mul(leveragedToken.exchangeRate());
        assertApproxEqRel(
            baseAssetAmountIn,
            leveragedTokenValue,
            0.01e18,
            "Value of leveraged token minted does not match baseAssetAmountIn."
        );

        // Redeem half of the owned leveraged tokens for zapAsset
        // Temp using half until issue with LT is resolved
        IERC20 zapAsset = IERC20(zapSwap.zapAsset());
        uint256 leveragedTokenAmountToRedeem = leveragedToken.balanceOf(
            address(this)
        ) / 2;
        uint256 halfZapAssetAmountOut = zapAssetAmountOut / 2;
        uint256 minZapAssetAmountOut = (zapAssetAmountOut / 200) * 98;
        leveragedToken.approve(address(zapSwap), leveragedTokenAmountToRedeem);
        uint256 zapAssetBalanceBeforeRedeem = zapAsset.balanceOf(address(this));
        zapSwap.redeem(
            address(leveragedToken),
            leveragedTokenAmountToRedeem,
            minZapAssetAmountOut
        );

        // Verify zapAsset balance received from redemption has a max 2% deviation from baseAssetAmountIn
        uint256 zapAssetBalanceAfterRedeem = zapAsset.balanceOf(address(this)) -
            zapAssetBalanceBeforeRedeem;
        assertApproxEqRel(
            halfZapAssetAmountOut,
            zapAssetBalanceAfterRedeem,
            0.02e18,
            "Didn't receive enough of the zapAsset from leveraged token redemption."
        );
    }

    function testRedeemRevertDirectZapSwap() public {
        redeemRevert(zapSwapUSDC, 1000e6);
    }

    function testRedeemRevertIndirectZapSwap() public {
        redeemRevert(zapSwapDAI, 1000e18);
    }

    function redeemRevert(IZapSwap zapSwap, uint256 amountIn) public {
        // Mint some leveraged tokens
        mintLeveragedTokenWithZapAsset(zapSwap, amountIn);
        _executeOrder(address(leveragedToken));
        // Redeem with amount zero
        assertEq(zapSwap.redeem(address(leveragedToken), 0, 0), 0);
        // Redeem with wrong address
        vm.expectRevert();
        zapSwap.redeem(address(5), 900e18, 0);
        // Redeem more than owned
        vm.expectRevert();
        zapSwapUSDC.redeem(address(leveragedToken), 1100e6, 0);
        // Redeem with higher minAmountOut
        vm.expectRevert();
        zapSwapUSDC.redeem(address(leveragedToken), 500e18, 600e18);
    }

    function testMultipleUserActivity() public {
        // Activity in this test:
        // testSuite mints for 4000 USDC
        // alice mints for 2000 DAI
        // bob mints for 5000 USDT
        // testSuite redeems 1/4 of its LTs for USDT
        // bob redeems for 1/2 of his LTs for DAI

        uint256 suiteIn = 4000e6;
        uint256 aliceIn = 2000e18;
        uint256 bobIn = 5000e6;

        IERC20 usdc = IERC20(zapSwapUSDC.zapAsset());
        IERC20 dai = IERC20(zapSwapDAI.zapAsset());
        IERC20 usdt = IERC20(zapSwapUSDT.zapAsset());

        _mintTokensFor(address(usdc), address(this), suiteIn);
        _mintTokensFor(address(dai), alice, aliceIn);
        _mintTokensFor(address(usdt), bob, bobIn);

        // TestSuite mints
        usdc.approve(address(zapSwapUSDC), suiteIn);
        zapSwapUSDC.mint(address(leveragedToken), suiteIn, 0);
        _executeOrder(address(leveragedToken));

        // Alice mints
        vm.prank(alice);
        dai.approve(address(zapSwapDAI), aliceIn);
        vm.prank(alice);
        zapSwapDAI.mint(address(leveragedToken), aliceIn, 0);
        _executeOrder(address(leveragedToken));

        // Bob mints
        vm.prank(bob);
        usdt.approve(address(zapSwapUSDT), bobIn);
        vm.prank(bob);
        zapSwapUSDT.mint(address(leveragedToken), bobIn, 0);
        _executeOrder(address(leveragedToken));

        // TestSuite withdraws 1/4 of its leveraged tokens
        uint256 suiteLeveragedTokenOut = leveragedToken
            .balanceOf(address(this))
            .div(4e18);
        leveragedToken.approve(address(zapSwapUSDT), suiteLeveragedTokenOut);
        zapSwapUSDT.redeem(address(leveragedToken), suiteLeveragedTokenOut, 0);

        // Bob withdraws 1/2 his leveraged tokens for DAI
        uint256 bobLeveragedTokenOut = leveragedToken.balanceOf(bob).div(2e18);
        vm.prank(bob);
        leveragedToken.approve(address(zapSwapDAI), bobLeveragedTokenOut);
        vm.prank(bob);
        zapSwapDAI.redeem(address(leveragedToken), bobLeveragedTokenOut, 0);

        // Verify testSuite's leveraged token and USDT holdings
        uint256 suiteLtValue = leveragedToken.balanceOf(address(this)).mul(
            leveragedToken.exchangeRate()
        );
        assertApproxEqRel(3000e18, suiteLtValue, 0.03e18);
        assertApproxEqAbs(1000e6, usdt.balanceOf(address(this)), 0.03e18);

        // Verify Alice's leveraged token value
        uint256 aliceLtValue = leveragedToken.balanceOf(alice).mul(
            leveragedToken.exchangeRate()
        );
        assertApproxEqRel(2000e18, aliceLtValue, 0.03e18);

        // Verify Bob's leveraged token and DAI holdings
        uint256 bobLtValue = leveragedToken.balanceOf(bob).mul(
            leveragedToken.exchangeRate()
        );
        assertApproxEqRel(2500e18, bobLtValue, 0.03e18);
        assertApproxEqRel(2500e18, dai.balanceOf(bob), 0.03e18);
    }

    // The following tests are testing the internal swap functions
    // of the direct and indirect ZapSwaps using the WrappedZapSwap

    function testSwapUSDCforBaseAsset() public {
        swapDirectZapAssetForBaseAsset(wrappedZapSwapUSDC, 10000e6, 10000e18);
    }

    function swapDirectZapAssetForBaseAsset(
        WrappedZapSwapDirect wrappedZapSwap,
        uint256 zapAssetAmountIn,
        uint256 baseAssetAmountOut
    ) public {
        // Mint and transfer tokens to wrapped zapSwap
        IERC20 zapAsset = IERC20(wrappedZapSwap.zapAsset());
        mintAndTransferTo(zapAsset, zapAssetAmountIn, address(wrappedZapSwap));
        assertEq(zapAsset.balanceOf(address(wrappedZapSwap)), zapAssetAmountIn);

        // Swap zapAsset for baseAsset
        wrappedZapSwap.swapZapAssetForBaseAsset(zapAssetAmountIn);
        assertApproxEqRel(
            baseAssetAmountOut,
            addressProvider.baseAsset().balanceOf(address(wrappedZapSwap)),
            0.01e18
        );
    }

    function testSwapBaseAssetForUSDC() public {
        swapDirectBaseAssetForZapAsset(wrappedZapSwapUSDC, 10000e18, 10000e6);
    }

    function swapDirectBaseAssetForZapAsset(
        WrappedZapSwapDirect wrappedZapSwap,
        uint256 baseAssetAmountIn,
        uint256 zapAssetAmountOut
    ) public {
        // Mint and transfer baseAsset to wrapped zapSwap
        mintAndTransferTo(
            addressProvider.baseAsset(),
            baseAssetAmountIn,
            address(wrappedZapSwap)
        );
        assertEq(
            addressProvider.baseAsset().balanceOf(address(wrappedZapSwap)),
            baseAssetAmountIn
        );

        // Swap baseAsset for zapAsset
        wrappedZapSwap.swapBaseAssetForZapAsset(baseAssetAmountIn);
        IERC20 zapAsset = IERC20(wrappedZapSwap.zapAsset());
        assertApproxEqRel(
            zapAssetAmountOut,
            zapAsset.balanceOf(address(wrappedZapSwap)),
            0.01e18
        );
    }

    function testSwapUSDTforBaseAsset() public {
        swapIndirectZapAssetForBaseAsset(wrappedZapSwapUSDT, 10000e6, 10000e18);
    }

    function testSwapDAIforBaseAsset() public {
        swapIndirectZapAssetForBaseAsset(wrappedZapSwapDAI, 10000e18, 10000e18);
    }

    function swapIndirectZapAssetForBaseAsset(
        WrappedZapSwapIndirect wrappedZapSwap,
        uint256 zapAssetAmountIn,
        uint256 baseAssetAmountOut
    ) public {
        // Mint and transfer tokens to wrapped zapSwap
        IERC20 zapAsset = IERC20(wrappedZapSwap.zapAsset());
        mintAndTransferTo(zapAsset, zapAssetAmountIn, address(wrappedZapSwap));
        assertEq(zapAsset.balanceOf(address(wrappedZapSwap)), zapAssetAmountIn);

        // Swap zapAsset for baseAsset
        wrappedZapSwap.swapZapAssetForBaseAsset(zapAssetAmountIn);
        assertApproxEqRel(
            baseAssetAmountOut,
            addressProvider.baseAsset().balanceOf(address(wrappedZapSwap)),
            0.01e18
        );
    }

    function testSwapBaseAssetForUSDT() public {
        swapIndirectBaseAssetForZapAsset(wrappedZapSwapUSDT, 10000e18, 10000e6);
    }

    function testSwapBaseAssetForDAI() public {
        swapIndirectBaseAssetForZapAsset(wrappedZapSwapDAI, 10000e18, 10000e18);
    }

    function swapIndirectBaseAssetForZapAsset(
        WrappedZapSwapIndirect wrappedZapSwap,
        uint256 baseAssetAmountIn,
        uint256 zapAssetAmountOut
    ) public {
        // Mint and transfer baseAsset to wrapped zapSwap
        mintAndTransferTo(
            addressProvider.baseAsset(),
            baseAssetAmountIn,
            address(wrappedZapSwap)
        );
        assertEq(
            addressProvider.baseAsset().balanceOf(address(wrappedZapSwap)),
            baseAssetAmountIn
        );

        // Swap baseAsset for zapAsset
        wrappedZapSwap.swapBaseAssetForZapAsset(baseAssetAmountIn);
        IERC20 zapAsset = IERC20(wrappedZapSwap.zapAsset());
        assertApproxEqRel(
            zapAssetAmountOut,
            zapAsset.balanceOf(address(wrappedZapSwap)),
            0.01e18
        );
    }

    // The following functions are helpers to reduce code duplication

    // Replace this function and just directly mint to the receiver
    function mintAndTransferTo(
        IERC20 asset,
        uint256 amount,
        address receiver
    ) public {
        _mintTokensFor(address(asset), address(this), amount);
        asset.approve(receiver, amount);
        asset.transfer(receiver, amount);
    }

    function mintLeveragedTokenWithZapAsset(
        IZapSwap zapSwap,
        uint256 amountIn_
    ) public returns (uint256) {
        IERC20 zapAsset = IERC20(zapSwap.zapAsset());
        zapAsset.approve(address(zapSwap), amountIn_);
        _mintTokensFor(address(zapAsset), address(this), amountIn_);
        zapSwap.mint(address(leveragedToken), amountIn_, 0);
        return leveragedToken.balanceOf(address(this));
    }
}
