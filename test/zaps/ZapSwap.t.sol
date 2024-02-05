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
import {Errors} from "../../src/libraries/Errors.sol";
import {ScaledNumber} from "../../src/libraries/ScaledNumber.sol";

import {ZapSwap} from "../../src/zaps/ZapSwap.sol";

contract WrappedZapSwap is ZapSwap {
    constructor(
        address addressProvider_,
        address velodromeRouter_,
        address uniswapRouter_
    ) ZapSwap(addressProvider_, velodromeRouter_, uniswapRouter_) {}

    function swapAsset(
        uint256 amountIn_,
        address assetIn_,
        address assetOut_,
        IZapSwap.SwapData memory swapData_,
        bool zapAssetForBaseAsset_
    ) public {
        _swapAsset(
            amountIn_,
            assetIn_,
            assetOut_,
            swapData_,
            zapAssetForBaseAsset_
        );
    }
}

contract ZapSwapTest is IntegrationTest {
    using ScaledNumber for uint256;

    // ZapSwap contract as deployed
    ZapSwap public zapSwap;

    // Wrapped ZapSwap for testing internal swap functionality
    WrappedZapSwap public wrappedZapSwap;

    ILeveragedToken public leveragedToken;

    IERC20 public baseAsset;
    uint256 public ethPrice;
    address public veloDefaultFactory;

    function setUp() public override {
        super.setUp();

        baseAsset = addressProvider.baseAsset();
        ethPrice = synthetixHandler.assetPrice("ETH");
        veloDefaultFactory = Contracts.VELODROME_DEFAULT_FACTORY;

        // Create new zapSwap
        zapSwap = new ZapSwap(
            address(addressProvider),
            Contracts.VELODROME_ROUTER,
            Contracts.UNISWAP_V3_ROUTER
        );
        // Set swap data for zapSwap
        setSwapDataForAllZapAssets(zapSwap);

        // Create new wrappedZapSwap
        wrappedZapSwap = new WrappedZapSwap(
            address(addressProvider),
            Contracts.VELODROME_ROUTER,
            Contracts.UNISWAP_V3_ROUTER
        );
        // Set swap data for wrappedZapSwap
        setSwapDataForAllZapAssets(wrappedZapSwap);

        // Create ETH2L leveraged token
        (address longTokenAddress_, ) = leveragedTokenFactory
            .createLeveragedTokens(
                Symbols.ETH,
                2e18,
                Config.REBALANCE_THRESHOLD
            );
        leveragedToken = ILeveragedToken(longTokenAddress_);
    }

    function testSwapPaths() public {
        // Test USDT swap path
        IZapSwap.SwapData memory usdtSwapPath = zapSwap.swapData(Tokens.USDT);
        assertEq(usdtSwapPath.supported, true);
        assertEq(usdtSwapPath.direct, false);
        assertEq(usdtSwapPath.bridgeAsset, Tokens.USDCE);
        assertEq(usdtSwapPath.zapAssetSwapStable, true);
        assertEq(usdtSwapPath.baseAssetSwapStable, true);
        assertEq(usdtSwapPath.zapAssetFactory, veloDefaultFactory);
        assertEq(usdtSwapPath.baseAssetFactory, veloDefaultFactory);
        assertEq(usdtSwapPath.swapZapAssetOnUni, false);
        assertEq(usdtSwapPath.uniPoolFee, 0);
    }

    function testUpdateSwapPath() public {
        uint256 supportedAssets = zapSwap.supportedZapAssets().length;
        // Update an existing zap asset
        IZapSwap.SwapData memory _wethSwapData = IZapSwap.SwapData({
            supported: true,
            direct: false,
            bridgeAsset: Tokens.USDCE,
            zapAssetSwapStable: false,
            baseAssetSwapStable: true,
            zapAssetFactory: veloDefaultFactory,
            baseAssetFactory: veloDefaultFactory,
            swapZapAssetOnUni: false,
            uniPoolFee: 0
        });
        zapSwap.setAssetSwapData(Tokens.WETH, _wethSwapData);

        // Verify no change in number of supported assets
        assertEq(zapSwap.supportedZapAssets().length, supportedAssets);
        // Verify updated swap data is correct
        IZapSwap.SwapData memory wethSwapData = zapSwap.swapData(Tokens.WETH);
        assertEq(wethSwapData.supported, true);
        assertEq(wethSwapData.direct, false);
        assertEq(wethSwapData.bridgeAsset, Tokens.USDCE);
        assertEq(wethSwapData.zapAssetSwapStable, false);
        assertEq(wethSwapData.baseAssetSwapStable, true);
        assertEq(wethSwapData.zapAssetFactory, veloDefaultFactory);
        assertEq(wethSwapData.baseAssetFactory, veloDefaultFactory);
        assertEq(wethSwapData.swapZapAssetOnUni, false);
        assertEq(wethSwapData.uniPoolFee, 0);
    }

    function testSetSwapPathRevert() public {
        // Test non-owner trying to change swapData
        IZapSwap.SwapData memory dummySD = IZapSwap.SwapData({
            supported: true,
            direct: false,
            bridgeAsset: Tokens.USDC,
            zapAssetSwapStable: false,
            baseAssetSwapStable: true,
            zapAssetFactory: veloDefaultFactory,
            baseAssetFactory: veloDefaultFactory,
            swapZapAssetOnUni: false,
            uniPoolFee: 0
        });
        vm.prank(alice);
        vm.expectRevert();
        zapSwap.setAssetSwapData(address(9), dummySD);

        // Test setting uniSwap path with unsupported bridge assets
        IZapSwap.SwapData memory unsupprtedBridgeSD = IZapSwap.SwapData({
            supported: true,
            direct: false,
            bridgeAsset: Tokens.CRV,
            zapAssetSwapStable: false,
            baseAssetSwapStable: false,
            zapAssetFactory: veloDefaultFactory,
            baseAssetFactory: veloDefaultFactory,
            swapZapAssetOnUni: true,
            uniPoolFee: 0
        });
        vm.expectRevert();
        zapSwap.setAssetSwapData(address(9), unsupprtedBridgeSD);
        IZapSwap.SwapData memory unsupprtedBridgeSDTwo = IZapSwap.SwapData({
            supported: true,
            direct: false,
            bridgeAsset: Tokens.USDC,
            zapAssetSwapStable: false,
            baseAssetSwapStable: false,
            zapAssetFactory: veloDefaultFactory,
            baseAssetFactory: veloDefaultFactory,
            swapZapAssetOnUni: true,
            uniPoolFee: 0
        });
        vm.expectRevert();
        zapSwap.setAssetSwapData(Tokens.USDC, unsupprtedBridgeSDTwo);
    }

    function testSupportedAssets() public {
        address[] memory supportedAssets = zapSwap.supportedZapAssets();
        assertEq(supportedAssets[0], Tokens.USDCE);
        assertEq(supportedAssets[1], Tokens.USDT);
        assertEq(supportedAssets[2], Tokens.DAI);
        assertEq(supportedAssets[3], Tokens.USDC);
        assertEq(supportedAssets[4], Tokens.WETH);
        assertEq(zapSwap.supportedZapAssets().length, 5);
    }

    function testUnsupportedZapAsset() public {
        vm.expectRevert(IZapSwap.UnsupportedAsset.selector);
        zapSwap.mint(Tokens.CRV, address(leveragedToken), 100e18, 0);
        vm.expectRevert(IZapSwap.UnsupportedAsset.selector);
        zapSwap.redeem(Tokens.CRV, address(leveragedToken), 100e18, 0);
    }

    function testRemoveZapAsset() public {
        // Verify removing a zap asset with bridgeDependency reverts
        vm.expectRevert(
            abi.encodeWithSelector(
                IZapSwap.BridgeAssetDependency.selector,
                Tokens.USDT
            )
        );
        zapSwap.removeAssetSwapData(Tokens.USDCE);

        // Verify removing an unsupported asset reverts correctly
        vm.expectRevert(IZapSwap.UnsupportedAsset.selector);
        zapSwap.removeAssetSwapData(Tokens.CRV);

        // Verify only owner can remove a zap asset
        vm.prank(alice);
        vm.expectRevert();
        zapSwap.removeAssetSwapData(Tokens.DAI);

        // Remove the target asset
        address targetAsset = Tokens.USDT;
        zapSwap.removeAssetSwapData(targetAsset);
        // Verify swap data indicates that the asset is not supported anymore
        assertEq(zapSwap.swapData(targetAsset).supported, false);
        // Verify zap asset is not included in the supportedZapAssets array
        (, bool found) = _findIndex(targetAsset, zapSwap.supportedZapAssets());
        assertEq(found, false);
        assertEq(zapSwap.supportedZapAssets().length, 4);

        // Verfiy minting with the removed asset doesn't work anymore
        vm.expectRevert(IZapSwap.UnsupportedAsset.selector);
        zapSwap.mint(targetAsset, address(leveragedToken), 100e18, 0);
    }

    function testSimpleMintWithUSDCe() public {
        simpleMint(Tokens.USDCE, 1000e6, 1000e18);
    }

    function testSimpleMintWithUSDT() public {
        simpleMint(Tokens.USDT, 1000e6, 1000e18);
    }

    function testSimpleMintWithDAI() public {
        simpleMint(Tokens.DAI, 1000e18, 1000e18);
    }

    function testSimpleMintWithUSDC() public {
        simpleMint(Tokens.USDC, 1000e6, 1000e18);
    }

    function testSimpleMintWithWETH() public {
        simpleMint(Tokens.WETH, 1e18, ethPrice);
    }

    function simpleMint(
        address zapAssetIn,
        uint256 amountIn,
        uint256 expectedAmountOut
    ) public {
        // Mint tokens for user and approve zap
        _mintTokensFor(zapAssetIn, address(this), amountIn);
        IERC20(zapAssetIn).approve(address(zapSwap), amountIn);
        // Mint leveraged tokens with zap
        zapSwap.mint(zapAssetIn, address(leveragedToken), amountIn, 0);

        // Assert amount of leveraged tokens minted is correct
        assertApproxEqRel(
            leveragedToken.balanceOf(address(this)),
            expectedAmountOut,
            0.01e18,
            "Number of leveraged tokens minted incorrect"
        );

        // Assert baseAsset value of leveraged tokens is correct
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
        mintRevert(Tokens.USDCE, 1000e6, 1000e18);
    }

    function testMintRevertIndirectZapSwap() public {
        mintRevert(Tokens.USDT, 1000e18, 1000e18);
    }

    function mintRevert(
        address zapAssetIn,
        uint256 amountIn,
        uint256 expectedAmountOut
    ) public {
        // Mint tokens for user and approve zap
        _mintTokensFor(zapAssetIn, address(this), amountIn);
        IERC20(zapAssetIn).approve(address(zapSwap), amountIn);

        // Mint with 0 zapAsset
        assertEq(zapSwap.mint(zapAssetIn, address(leveragedToken), 0, 0), 0);

        // Mint with wrong lt address
        vm.expectRevert(Errors.InvalidAddress.selector);
        zapSwap.mint(zapAssetIn, address(6), amountIn, 0);

        // Mint with higher amountIn
        vm.expectRevert();
        zapSwap.mint(zapAssetIn, address(leveragedToken), amountIn * 2, 0);

        // Mint with higher minAmountOut
        vm.expectRevert();
        zapSwap.mint(
            zapAssetIn,
            address(leveragedToken),
            amountIn,
            expectedAmountOut * 2
        );
    }

    function testSimpleRedeemWithUSDCe() public {
        simpleRedeem(Tokens.USDCE, 1000e18, 1000e6);
    }

    function testSimpleRedeemWithUSDT() public {
        simpleRedeem(Tokens.USDT, 1000e18, 1000e6);
    }

    function testSimpleRedeemWithDAI() public {
        simpleRedeem(Tokens.DAI, 1000e18, 1000e18);
    }

    function testSimpleRedeemWithUSDC() public {
        simpleRedeem(Tokens.USDC, 1000e18, 1000e6);
    }

    function testSimpleRedeemWithWETH() public {
        simpleRedeem(Tokens.WETH, ethPrice, 1e18);
    }

    function simpleRedeem(
        address zapAssetOut,
        uint256 baseAssetAmountIn,
        uint256 zapAssetAmountOut
    ) public {
        // Mint leveraged tokens with baseAsset and without using the zap
        // IERC20 baseAsset = IERC20(addressProvider.baseAsset());
        _mintTokensFor(address(baseAsset), address(this), baseAssetAmountIn);
        baseAsset.approve(address(leveragedToken), baseAssetAmountIn);
        leveragedToken.mint(baseAssetAmountIn, 0);
        _executeOrder(address(leveragedToken));
        assertEq(leveragedToken.balanceOf(address(this)), baseAssetAmountIn);

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
        IERC20 zapAsset = IERC20(zapAssetOut);
        uint256 leveragedTokenAmountToRedeem = leveragedToken.balanceOf(
            address(this)
        ) / 2;
        uint256 halfZapAssetAmountOut = zapAssetAmountOut.div(2e18);
        uint256 minZapAssetAmountOut = zapAssetAmountOut.div(200e18).mul(97e18);
        leveragedToken.approve(address(zapSwap), leveragedTokenAmountToRedeem);
        uint256 zapAssetBalanceBeforeRedeem = zapAsset.balanceOf(address(this));
        zapSwap.redeem(
            zapAssetOut,
            address(leveragedToken),
            leveragedTokenAmountToRedeem,
            minZapAssetAmountOut
        );

        // Assert still holding 1/2 of the leveraged tokens
        assertEq(
            leveragedToken.balanceOf(address(this)),
            leveragedTokenAmountToRedeem, // Is equal to half of the original amount
            "Holding an incorrect amount of leveraged tokens after redemption."
        );
        // Verify zapAsset balance received from redemption has a max 2% deviation from baseAssetAmountIn
        uint256 zapAssetBalanceAfterRedeem = zapAsset.balanceOf(address(this)) -
            zapAssetBalanceBeforeRedeem;
        assertApproxEqRel(
            halfZapAssetAmountOut,
            zapAssetBalanceAfterRedeem,
            0.03e18,
            "Did not receive enough zapAsset from leveraged token redemption."
        );
    }

    function testRedeemRevertDirectZapSwap() public {
        redeemRevert(Tokens.USDCE, 1000e6);
    }

    function testRedeemRevertIndirectZapSwap() public {
        redeemRevert(Tokens.DAI, 1000e18);
    }

    function redeemRevert(address zapAssetAddress, uint256 amountIn) public {
        // Mint some leveraged tokens with zapAsset
        uint256 leveragedTokenAmount = mintLeveragedTokenWithZapAsset(
            zapAssetAddress,
            amountIn
        );
        _executeOrder(address(leveragedToken));
        leveragedToken.approve(address(zapSwap), leveragedTokenAmount);

        // Redeem with amount zero
        assertEq(
            zapSwap.redeem(zapAssetAddress, address(leveragedToken), 0, 0),
            0
        );
        // Redeem with wrong address
        vm.expectRevert(Errors.InvalidAddress.selector);
        zapSwap.redeem(zapAssetAddress, address(5), leveragedTokenAmount, 0);
        // Redeem more than owned
        vm.expectRevert();
        zapSwap.redeem(
            zapAssetAddress,
            address(leveragedToken),
            leveragedTokenAmount * 2,
            0
        );
        // Redeem with higher minAmountOut: 50% of leveraged tokens, 60% of amountIn
        uint256 tooLargeAmountOut = (amountIn / 10) * 6;
        vm.expectRevert(Errors.InsufficientAmount.selector);
        zapSwap.redeem(
            zapAssetAddress,
            address(leveragedToken),
            leveragedTokenAmount / 2,
            tooLargeAmountOut
        );
    }

    function testMultipleUserActivity() public {
        // Activity in this test:
        // testSuite mints for 4000 USDCe
        // alice mints for 2000 DAI
        // bob mints for 5000 USDT
        // testSuite redeems 1/4 of its LTs for USDC
        // bob redeems for 1/2 of his LTs for DAI

        uint256 suiteIn = 4000e6;
        uint256 aliceIn = 2000e18;
        uint256 bobIn = 5000e6;

        IERC20 usdce = IERC20(Tokens.USDCE);
        IERC20 dai = IERC20(Tokens.DAI);
        IERC20 usdt = IERC20(Tokens.USDT);
        IERC20 usdc = IERC20(Tokens.USDC);

        _mintTokensFor(address(usdce), address(this), suiteIn);
        _mintTokensFor(address(dai), alice, aliceIn);
        _mintTokensFor(address(usdt), bob, bobIn);

        // TestSuite mints for 4000 USDCe
        usdce.approve(address(zapSwap), suiteIn);
        zapSwap.mint(address(usdce), address(leveragedToken), suiteIn, 0);
        _executeOrder(address(leveragedToken));

        // Alice mints for 2000 DAI
        vm.prank(alice);
        dai.approve(address(zapSwap), aliceIn);
        vm.prank(alice);
        zapSwap.mint(address(dai), address(leveragedToken), aliceIn, 0);
        _executeOrder(address(leveragedToken));

        // Bob mints for 5000USDT
        vm.prank(bob);
        usdt.approve(address(zapSwap), bobIn);
        vm.prank(bob);
        zapSwap.mint(address(usdt), address(leveragedToken), bobIn, 0);
        _executeOrder(address(leveragedToken));

        // TestSuite redeems 1/4 of its leveraged tokens for USDC
        uint256 suiteLeveragedTokenOut = leveragedToken
            .balanceOf(address(this))
            .div(4e18);
        leveragedToken.approve(address(zapSwap), suiteLeveragedTokenOut);
        zapSwap.redeem(
            address(usdc),
            address(leveragedToken),
            suiteLeveragedTokenOut,
            0
        );

        // Bob redeems 1/2 of his leveraged tokens for DAI
        uint256 bobLeveragedTokenOut = leveragedToken.balanceOf(bob).div(2e18);
        vm.prank(bob);
        leveragedToken.approve(address(zapSwap), bobLeveragedTokenOut);
        vm.prank(bob);
        zapSwap.redeem(
            address(dai),
            address(leveragedToken),
            bobLeveragedTokenOut,
            0
        );

        // Verify testSuite leveraged token and USDC holdings
        uint256 suiteLtValue = leveragedToken.balanceOf(address(this)).mul(
            leveragedToken.exchangeRate()
        );
        assertApproxEqRel(3000e18, suiteLtValue, 0.03e18);
        assertApproxEqRel(1000e6, usdc.balanceOf(address(this)), 0.03e18);

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
    // of the ZapSwap using the WrappedZapSwap contract

    function testSwapUSDCeforBaseAsset() public {
        swapAssetForAsset(
            Tokens.USDCE,
            address(baseAsset),
            10000e6,
            10000e18,
            wrappedZapSwap.swapData(Tokens.USDCE),
            true
        );
    }

    function testSwapBaseAssetForUSDCe() public {
        swapAssetForAsset(
            address(baseAsset),
            Tokens.USDCE,
            10000e18,
            10000e6,
            wrappedZapSwap.swapData(Tokens.USDCE),
            false
        );
    }

    function testSwapUSDTforBaseAsset() public {
        swapAssetForAsset(
            Tokens.USDT,
            address(baseAsset),
            10000e6,
            10000e18,
            wrappedZapSwap.swapData(Tokens.USDT),
            true
        );
    }

    function testSwapBaseAssetForUSDT() public {
        swapAssetForAsset(
            address(baseAsset),
            Tokens.USDT,
            10000e18,
            10000e6,
            wrappedZapSwap.swapData(Tokens.USDT),
            false
        );
    }

    function testSwapDAIforBaseAsset() public {
        swapAssetForAsset(
            Tokens.DAI,
            address(baseAsset),
            10000e18,
            10000e18,
            wrappedZapSwap.swapData(Tokens.DAI),
            true
        );
    }

    function testSwapBaseAssetForDAI() public {
        swapAssetForAsset(
            address(baseAsset),
            Tokens.DAI,
            10000e18,
            10000e18,
            wrappedZapSwap.swapData(Tokens.DAI),
            false
        );
    }

    function testSwapUSDCforBaseAsset() public {
        swapAssetForAsset(
            Tokens.USDC,
            address(baseAsset),
            10000e6,
            10000e18,
            wrappedZapSwap.swapData(Tokens.USDC),
            true
        );
    }

    function testSwapBaseAssetForUSDC() public {
        swapAssetForAsset(
            address(baseAsset),
            Tokens.USDC,
            10000e18,
            10000e6,
            wrappedZapSwap.swapData(Tokens.USDC),
            false
        );
    }

    function testSwapWETHforBaseAsset() public {
        swapAssetForAsset(
            Tokens.WETH,
            address(baseAsset),
            1e18,
            ethPrice,
            wrappedZapSwap.swapData(Tokens.WETH),
            true
        );
    }

    function testSwapBaseAssetForWETH() public {
        swapAssetForAsset(
            address(baseAsset),
            Tokens.WETH,
            ethPrice,
            1e18,
            wrappedZapSwap.swapData(Tokens.WETH),
            false
        );
    }

    function swapAssetForAsset(
        address assetIn_,
        address assetOut_,
        uint256 assetAmountIn_,
        uint256 expectedAmountOut_,
        IZapSwap.SwapData memory swapData_,
        bool zapAssetForBaseAsset_
    ) public {
        IERC20 assetIn = IERC20(assetIn_);
        IERC20 assetOut = IERC20(assetOut_);

        // Mint assetIn to wrapped zapSwap
        _mintTokensFor(
            address(assetIn),
            address(wrappedZapSwap),
            assetAmountIn_
        );
        assertEq(assetIn.balanceOf(address(wrappedZapSwap)), assetAmountIn_);

        wrappedZapSwap.swapAsset(
            assetAmountIn_,
            assetIn_,
            assetOut_,
            swapData_,
            zapAssetForBaseAsset_
        );

        // Verify successful swap
        assertEq(assetIn.balanceOf(address(wrappedZapSwap)), 0);
        assertApproxEqRel(
            expectedAmountOut_,
            assetOut.balanceOf(address(wrappedZapSwap)),
            0.01e18
        );
    }

    // Helper functions

    function setSwapDataForAllZapAssets(ZapSwap zapSwap_) public {
        // Add USDC.e data
        IZapSwap.SwapData memory _usdceSwapData = IZapSwap.SwapData({
            supported: true,
            direct: true,
            bridgeAsset: address(0),
            zapAssetSwapStable: true,
            baseAssetSwapStable: true,
            zapAssetFactory: veloDefaultFactory,
            baseAssetFactory: veloDefaultFactory,
            swapZapAssetOnUni: false,
            uniPoolFee: 0
        });
        zapSwap_.setAssetSwapData(Tokens.USDCE, _usdceSwapData);

        // Add USDT data
        IZapSwap.SwapData memory _usdtSwapData = IZapSwap.SwapData({
            supported: true,
            direct: false,
            bridgeAsset: Tokens.USDCE,
            zapAssetSwapStable: true,
            baseAssetSwapStable: true,
            zapAssetFactory: veloDefaultFactory,
            baseAssetFactory: veloDefaultFactory,
            swapZapAssetOnUni: false,
            uniPoolFee: 0
        });
        zapSwap_.setAssetSwapData(Tokens.USDT, _usdtSwapData);

        // Add DAI data
        IZapSwap.SwapData memory _daiSwapData = IZapSwap.SwapData({
            supported: true,
            direct: false,
            bridgeAsset: Tokens.USDCE,
            zapAssetSwapStable: true,
            baseAssetSwapStable: true,
            zapAssetFactory: veloDefaultFactory,
            baseAssetFactory: veloDefaultFactory,
            swapZapAssetOnUni: false,
            uniPoolFee: 0
        });
        zapSwap_.setAssetSwapData(Tokens.DAI, _daiSwapData);

        // Add USDC data
        IZapSwap.SwapData memory _usdcSwapData = IZapSwap.SwapData({
            supported: true,
            direct: false,
            bridgeAsset: Tokens.USDCE,
            zapAssetSwapStable: true,
            baseAssetSwapStable: true,
            zapAssetFactory: veloDefaultFactory,
            baseAssetFactory: veloDefaultFactory,
            swapZapAssetOnUni: true,
            uniPoolFee: 100
        });
        zapSwap_.setAssetSwapData(Tokens.USDC, _usdcSwapData);

        // Add WETH data
        IZapSwap.SwapData memory _wethSwapData = IZapSwap.SwapData({
            supported: true,
            direct: false,
            bridgeAsset: Tokens.USDCE,
            zapAssetSwapStable: true,
            baseAssetSwapStable: true,
            zapAssetFactory: veloDefaultFactory,
            baseAssetFactory: veloDefaultFactory,
            swapZapAssetOnUni: true,
            uniPoolFee: 500
        });
        zapSwap_.setAssetSwapData(Tokens.WETH, _wethSwapData);
    }

    function mintLeveragedTokenWithZapAsset(
        address zapAssetAddress,
        uint256 amountIn_
    ) public returns (uint256) {
        IERC20 zapAsset = IERC20(zapAssetAddress);
        zapAsset.approve(address(zapSwap), amountIn_);
        _mintTokensFor(address(zapAsset), address(this), amountIn_);
        zapSwap.mint(zapAssetAddress, address(leveragedToken), amountIn_, 0);
        return leveragedToken.balanceOf(address(this));
    }

    function _findIndex(
        address element_,
        address[] memory array_
    ) internal pure returns (uint, bool) {
        for (uint i = 0; i < array_.length; i++) {
            if (array_[i] == element_) {
                return (i, true);
            }
        }
        // Return a default value if the element is not found
        return (0, false);
    }
}
