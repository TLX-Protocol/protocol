// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {Tokens} from "../../src/libraries/Tokens.sol";
import {Contracts} from "../../src/libraries/Contracts.sol";
import {AddressKeys} from "../../src/libraries/AddressKeys.sol";
import {ParameterKeys} from "../../src/libraries/ParameterKeys.sol";
import {Config} from "../../src/libraries/Config.sol";
import {Symbols} from "../../src/libraries/Symbols.sol";
import {InitialMint} from "../../src/libraries/InitialMint.sol";
import {ScaledNumber} from "../../src/libraries/ScaledNumber.sol";

import {IVesting} from "../../src/interfaces/IVesting.sol";
import {IPerpsV2MarketData} from "../../src/interfaces/synthetix/IPerpsV2MarketData.sol";
import {IPerpsV2MarketConsolidated} from "../../src/interfaces/synthetix/IPerpsV2MarketConsolidated.sol";
import {IExchangeRates} from "../../src/interfaces/synthetix/IExchangeRates.sol";
import {AggregatorV2V3Interface} from "../../src/interfaces/chainlink/AggregatorV2V3Interface.sol";
import {IPerpsV2MarketData} from "../../src/interfaces/synthetix/IPerpsV2MarketData.sol";
import {IPerpsV2MarketConsolidated} from "../../src/interfaces/synthetix/IPerpsV2MarketConsolidated.sol";
import {IPerpsV2ExchangeRate} from "../../src/interfaces/synthetix/IPerpsV2ExchangeRate.sol";
import {ILeveragedToken} from "../../src/interfaces/ILeveragedToken.sol";
import {IRewards} from "../../src/interfaces/velodrome/IRewards.sol";
import {IVoter} from "../../src/interfaces/velodrome/IVoter.sol";

import {LeveragedTokenFactory} from "../../src/LeveragedTokenFactory.sol";
import {AddressProvider} from "../../src/AddressProvider.sol";
import {ParameterProvider} from "../../src/ParameterProvider.sol";
import {Referrals} from "../../src/Referrals.sol";
import {TlxToken} from "../../src/TlxToken.sol";
import {Airdrop} from "../../src/Airdrop.sol";
import {Staker} from "../../src/Staker.sol";
import {GenesisLocker} from "../../src/GenesisLocker.sol";
import {Bonding} from "../../src/Bonding.sol";
import {Vesting} from "../../src/Vesting.sol";
import {SynthetixHandler} from "../../src/SynthetixHandler.sol";
import {VelodromeVoterAutomation} from "../../src/helpers/VelodromeVoterAutomation.sol";

import {Base64} from "../../src/testing/Base64.sol";

import "forge-std/StdJson.sol";

contract IntegrationTest is Test {
    using stdStorage for StdStorage;
    using stdJson for string;
    using ScaledNumber for uint256;

    // Some notes on why this is commented out below
    string constant PYTH_URL = "https://hermes.pyth.network/api/get_vaa";

    mapping(string => string) public assetPythIds;

    // Users
    address public alice = 0xEcfcf2996C7c2908Fc050f5EAec633c01A937712;
    address public bob = 0x787626366D8a4B8a0175ea011EdBE25e77290Dd1;
    address public treasury = Config.DAO_TREASURY;
    address public rebalanceFeeReceiver = Config.REBALANCE_FEE_RECEIVER;

    // Contracts
    LeveragedTokenFactory public leveragedTokenFactory;
    AddressProvider public addressProvider;
    ParameterProvider public parameterProvider;
    Referrals public referrals;
    TlxToken public tlx;
    Airdrop public airdrop;
    Staker public staker;
    GenesisLocker public genesisLocker;
    Bonding public bonding;
    Vesting public vesting;
    SynthetixHandler public synthetixHandler;
    VelodromeVoterAutomation public voterAutomation;

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("OPTIMISM_RPC"), 122555729);

        // Set Pyth IDs
        assetPythIds[
            Symbols.ETH
        ] = "0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace";
        assetPythIds[
            Symbols.BTC
        ] = "0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43";
        assetPythIds[
            Symbols.SOL
        ] = "0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d";
        assetPythIds[
            Symbols.LINK
        ] = "0x8ac0c70fff57e9aefdf5edf44b51d62c2d433653cbb2cf5cc06bb115af04d221";
        assetPythIds[
            Symbols.OP
        ] = "0x385f64d993f7b77d8182ed5003d97c60aa3361f3cecfe711544d2d59165e9bdf";

        // AddressProvider Setup
        addressProvider = new AddressProvider();
        addressProvider.updateAddress(AddressKeys.TREASURY, treasury);
        addressProvider.addRebalancer(address(this));
        addressProvider.updateAddress(
            AddressKeys.REBALANCE_FEE_RECEIVER,
            rebalanceFeeReceiver
        );
        addressProvider.updateAddress(
            AddressKeys.BASE_ASSET,
            Config.BASE_ASSET
        );

        // ParameterProvider Setup
        parameterProvider = new ParameterProvider(address(addressProvider));
        parameterProvider.updateParameter(
            ParameterKeys.REDEMPTION_FEE,
            Config.REDEMPTION_FEE
        );
        parameterProvider.updateParameter(
            ParameterKeys.STREAMING_FEE,
            Config.STREAMING_FEE
        );
        parameterProvider.updateParameter(
            ParameterKeys.REBALANCE_FEE,
            Config.REBALANCE_FEE
        );
        parameterProvider.updateParameter(
            ParameterKeys.MAX_BASE_ASSET_AMOUNT_BUFFER,
            Config.MAX_BASE_ASSET_AMOUNT_BUFFER
        );
        addressProvider.updateAddress(
            AddressKeys.PARAMETER_PROVIDER,
            address(parameterProvider)
        );

        // Vesting Setup
        IVesting.VestingAmount[] memory amounts_ = new Vesting.VestingAmount[](
            2
        );
        amounts_[0] = IVesting.VestingAmount(alice, 100e18);
        amounts_[1] = IVesting.VestingAmount(bob, 200e18);
        vesting = new Vesting(
            address(addressProvider),
            Config.VESTING_DURATION,
            amounts_
        );
        addressProvider.updateAddress(AddressKeys.VESTING, address(vesting));

        // Bonding Setup
        bonding = new Bonding(
            address(addressProvider),
            Config.INITIAL_TLX_PER_SECOND,
            Config.PERIOD_DECAY_MULTIPLIER,
            Config.PERIOD_DURATION,
            Config.BASE_FOR_ALL_TLX
        );
        addressProvider.updateAddress(AddressKeys.BONDING, address(bonding));

        // LeveragedTokenFactory Setup
        leveragedTokenFactory = new LeveragedTokenFactory(
            address(addressProvider)
        );
        addressProvider.updateAddress(
            AddressKeys.LEVERAGED_TOKEN_FACTORY,
            address(leveragedTokenFactory)
        );

        // Referrals Setup
        referrals = new Referrals(
            address(addressProvider),
            Config.REBATE_PERCENT,
            Config.EARNINGS_PERCENT
        );
        addressProvider.updateAddress(
            AddressKeys.REFERRALS,
            address(referrals)
        );

        // Airdrop Setup
        airdrop = new Airdrop(
            address(addressProvider),
            bytes32(0),
            block.timestamp + Config.AIRDROP_CLAIM_PERIOD,
            Config.DIRECT_AIRDROP_AMOUNT
        );
        addressProvider.updateAddress(AddressKeys.AIRDROP, address(airdrop));

        // Staker Setup
        staker = new Staker(
            address(addressProvider),
            Config.STAKER_UNSTAKE_DELAY,
            Config.BASE_ASSET
        );
        addressProvider.updateAddress(AddressKeys.STAKER, address(staker));

        // SynthetixHandler Setup
        synthetixHandler = new SynthetixHandler(
            address(addressProvider),
            Contracts.PERPS_V2_MARKET_DATA,
            Contracts.PERPS_V2_MARKET_SETTINGS
        );
        addressProvider.updateAddress(
            AddressKeys.SYNTHETIX_HANDLER,
            address(synthetixHandler)
        );

        // TLX Token Setup
        tlx = new TlxToken(
            Config.TOKEN_NAME,
            Config.TOKEN_SYMBOL,
            address(addressProvider)
        );
        addressProvider.updateAddress(AddressKeys.TLX, address(tlx));

        genesisLocker = new GenesisLocker(
            address(addressProvider),
            Config.GENESIS_LOCKER_LOCK_TIME,
            address(tlx)
        );
        addressProvider.updateAddress(
            AddressKeys.GENESIS_LOCKER,
            address(genesisLocker)
        );

        tlx.mintInitialSupply(InitialMint.getData(addressProvider));

        // VelodromeVoterRunner Setup
        voterAutomation = new VelodromeVoterAutomation(
            address(addressProvider),
            Config.VOTER_INITIAL_TLX_PER_SECOND,
            Config.PERIOD_DECAY_MULTIPLIER,
            Config.PERIOD_DURATION,
            block.timestamp,
            Contracts.TLX_ETH_REWARDS,
            block.timestamp,
            0
        );
        IVoter voter_ = IVoter(IRewards(Contracts.TLX_ETH_REWARDS).voter());
        address governor_ = voter_.governor();
        vm.prank(governor_);
        voter_.whitelistToken(address(tlx), true);
    }

    receive() external payable {}

    function _mintTokensFor(
        address token_,
        address account_,
        uint256 amount_
    ) internal {
        // sUSD is weird, this is a workaround to fix minting for it.
        if (token_ == Tokens.SUSD) {
            token_ = 0x92bAc115d89cA17fd02Ed9357CEcA32842ACB4c2;
        }

        stdstore
            .target(token_)
            .sig(IERC20(token_).balanceOf.selector)
            .with_key(account_)
            .checked_write(amount_);
    }

    // default version using ETH as the target asset
    function _executeOrder() internal {
        uint256 currentTime = block.timestamp;
        uint256 searchTime = currentTime + 5;
        string memory vaa = _getVaa(Symbols.ETH, searchTime);
        bytes memory decoded = Base64.decode(vaa);
        bytes memory hexData = abi.encodePacked(decoded);
        bytes[] memory priceUpdateData = new bytes[](1);
        priceUpdateData[0] = hexData;
        _market(Symbols.ETH).executeOffchainDelayedOrder{value: 1 ether}(
            address(this),
            priceUpdateData
        );
    }

    function _executeOrder(address account_) internal {
        uint256 currentTime = block.timestamp;
        uint256 searchTime = currentTime + 5;
        string memory asset = ILeveragedToken(account_).targetAsset();
        string memory vaa = _getVaa(asset, searchTime);
        bytes memory decoded = Base64.decode(vaa);
        bytes memory hexData = abi.encodePacked(decoded);
        bytes[] memory priceUpdateData = new bytes[](1);
        priceUpdateData[0] = hexData;
        _market(asset).executeOffchainDelayedOrder{value: 1 ether}(
            account_,
            priceUpdateData
        );
    }

    function _modifyPrice(string memory asset_, uint256 multiplier_) internal {
        bytes32 key_ = bytes32(bytes(abi.encodePacked(asset_)));
        IExchangeRates exchangeRates_ = IExchangeRates(
            Contracts.EXCHANGE_RATES
        );
        AggregatorV2V3Interface aggregator = AggregatorV2V3Interface(
            exchangeRates_.aggregators(key_)
        );
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = aggregator.latestRoundData();

        require(answer > 0, "Invalid answer");
        uint256 newAnswer = uint256(answer).mul(multiplier_);
        vm.mockCall(
            address(aggregator),
            abi.encodeWithSelector(aggregator.latestRoundData.selector),
            abi.encode(
                uint80(roundId),
                int256(newAnswer),
                uint256(startedAt),
                uint256(updatedAt),
                uint80(answeredInRound)
            )
        );
        IPerpsV2MarketData.MarketData memory marketData_ = IPerpsV2MarketData(
            Contracts.PERPS_V2_MARKET_DATA
        ).marketDetailsForKey(_key(asset_));
        IPerpsV2MarketConsolidated market_ = IPerpsV2MarketConsolidated(
            marketData_.market
        );
        uint8 decimals_ = exchangeRates_.currencyKeyDecimals(key_);
        vm.mockCall(
            Contracts.PERPS_V2_EXCHANGE_RATE,
            abi.encodeWithSelector(
                IPerpsV2ExchangeRate.resolveAndGetPrice.selector,
                market_.baseAsset()
            ),
            abi.encode(
                _convertDecimals(decimals_, newAnswer),
                block.timestamp + 30 seconds
            )
        );
    }

    function _convertDecimals(
        uint8 from,
        uint256 rate
    ) internal pure returns (uint256) {
        if (from == 0 || from == 18) {
            return rate;
        }
        if (from < 18) {
            uint256 multiplier = 10 ** (18 - from);
            return rate * multiplier;
        }
        uint256 divisor = 10 ** (from - 18);
        return rate / divisor;
    }

    function _getVaa(
        string memory asset,
        uint256 publishTime
    ) internal returns (string memory) {
        string memory url = string.concat(
            PYTH_URL,
            "?id=",
            assetPythIds[asset],
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
