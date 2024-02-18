// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {Tokens} from "../../src/libraries/Tokens.sol";
import {Contracts} from "../../src/libraries/Contracts.sol";
import {AddressKeys} from "../../src/libraries/AddressKeys.sol";
import {ParameterKeys} from "../../src/libraries/ParameterKeys.sol";
import {Config} from "../../src/libraries/Config.sol";
import {Symbols} from "../../src/libraries/Symbols.sol";
import {InitialMint} from "../../src/libraries/InitialMint.sol";
import {ForkBlock} from "./ForkBlock.sol";

import {IVesting} from "../../src/interfaces/IVesting.sol";
import {IPerpsV2MarketData} from "../../src/interfaces/synthetix/IPerpsV2MarketData.sol";
import {IPerpsV2MarketConsolidated} from "../../src/interfaces/synthetix/IPerpsV2MarketConsolidated.sol";

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

import {Base64} from "../../src/testing/Base64.sol";

import "forge-std/StdJson.sol";

contract IntegrationTest is Test {
    using stdStorage for StdStorage;
    using stdJson for string;

    // Some notes on why this is commented out below
    // string constant PYTH_URL = "https://hermes.pyth.network/api/get_vaa";
    // string constant PYTH_ID =
    //     "0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace"; // ETH/USD
    string constant VAA =
        "UE5BVQEAAAADuAEAAAADDQBdPXDahGNNr23Wo+CIBkq9kZLHqI667+PA5fraNH918xy+0w/XbhLUvraNuaNEBYsYb5LhiY/2MgEhngj22e03AAMFiZExKBlpCCR0j8/kvO3bvsoQi7pFKiFfIePaw5Rn9nzGWGhl3WjGcEgH9I4nVa7UrnAbRqPMIaXLDLASlk0wAQZjulzaozrgAZrb3iog34sIxRMXbrOhmPmmPwmnBIvUbh4yi6egeUxf5S+95hg7dh8nwiEM0M0tqHvEz821vna7AQjnVJaM3w6iHnSThMkWydx633fhvMuUCRjxURW01stnBAOCBL1WMsGQWXDDHsdrES3MEuiNVYEkhY9K2uAiN+X9AAlOcZBXAU0Jb5izrcVrG8QOYKIWiVVkfq5Jsh/yPED7pV4RyGefKh5SkF95DLNqFZC8HjYMMqSh8gC4J0+bc4K3AQpZSA6i4rbOHZbxSlgoeG/fpeOcJf8aIl6Uv++kK8SM/xNe0FQA4R5jSo+wAfVijjOF2jTWDEX9hO6TJ69Y/WU6AQsbbzxflnBwq4hC5TtFjtusMLEDBlIzp7pYfWByk6MSkCk1YbguZ4/RWBH/X11Z/ETKVFuo3nWXDd2evwJY2EjxAQxlPMZa410JIXlnxIA4H3inO61sBMYWLJxR0ybKn0DtYH3N4ev40QJ+YOVuqAO0sIPqm69M12pxqVhKPlH/+KixAA0/nKdIHaz0SmC2nsFksxa30x8TJD6dR61fyaMdDIS6E03/HhJ8vT9bqPHHcfuLcAOPKGkhfmkWqPFPjhnRKONXAQ4Y+j5vmyD9l52Qn+tagF1TjAKiDVFNcQfBSiK06ThXC3hdJjj7Pt5Usf8SeKrAA6/+pf0RHgzNN728OsF3+z+VAA9+Do9+UOqPwhn/i3GiM1TvGhXDQwadPCwG9N/bhJq/my8eDlKd5sinXGIIE/A1w83wx4Pz1r3faxkWRniOu6zWABHhKHcCh8nLecCQTH8rOGwD6iIH3vM0YhWtpBKiyzkBahEGR1Ewin1v51O6D2QqQAeLDNyhkrW1hNJKLJDFNjpIABKzqVlIGGw6k+c/UUejYxYY9LFYRyYLFlBkZk2IO3l2ywoU1r6lfZlmiNLdsIw6x0loIy1fzfS1GjvRwbRmjjyFAWVzEgsAAAAAABrhAfrtrFhR4yubI7X5QRqMK6xKrj7U3XuBHdGnLqSqcQAAAAABy1tpAUFVV1YAAAAAAAbSX6oAACcQ1Z4XBgUcxMOAKhsGv2fZAZvH7pIBAFUA/2FJGpMREt3xvYFHzRtkE3X3n1glEm1mVICHRjT9Cs4AAAA3IM7epAAAAAAFSGFk////+AAAAABlcxIKAAAAAGVzEgkAAAA3DMMpcAAAAAAFgWxeCiya6yAcnUvKQ6WTHY+hZESCgVoOLtDwnokED5y2b6Eo/RCJ6ls/X/v8suW6/MSSp9FerSPbzooMjgGRNqpKwYnD73KDP9tSHlUYubhmLIQKv5PZhQGXWEDmq7Y23DDpuFo8DRQBF1Kxr1MRzQsQfhBJNI+4j3J1BUAHMGLhlkueL2BRfvVilCZwu92oEu5GL4GtbNyMbsivwthqdUvxmwqmlRQ6xdue3kiLMTXVQa8OxRIkKuhpr4w8sQy4T6DSpv/XeLnwksYn";

    // Users
    address public alice = 0xEcfcf2996C7c2908Fc050f5EAec633c01A937712;
    address public bob = 0x787626366D8a4B8a0175ea011EdBE25e77290Dd1;
    address public treasury = Config.TREASURY;
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

    function setUp() public virtual {
        vm.selectFork(
            vm.createFork(vm.envString("OPTIMISM_RPC"), ForkBlock.NUMBER)
        );

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
            address(addressProvider),
            Config.MAX_LEVERAGE
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

    function _executeOrder() internal {
        _executeOrder(address(this));
    }

    function _executeOrder(address account_) internal {
        // uint256 currentTime = block.timestamp;
        // uint256 searchTime = currentTime + 5;
        // string memory vaa = _getVaa(searchTime);
        string memory vaa = _getVaa();
        bytes memory decoded = Base64.decode(vaa);
        bytes memory hexData = abi.encodePacked(decoded);
        bytes[] memory priceUpdateData = new bytes[](1);
        priceUpdateData[0] = hexData;
        _market(Symbols.ETH).executeOffchainDelayedOrder{value: 1 ether}(
            account_,
            priceUpdateData
        );
    }

    // We used to use this API logic, allowing us to get it at any timestamp.
    // The endpoint is in the format https://hermes.pyth.network/api/get_vaa?id=0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace&publish_time=1702040074
    // However suddently the API became super flakey, and stopped working. Tried an alternative, and it was even worse
    // Realised that the timestamp is always roughly the same, so we can just hard code the VAA.
    // Although this will break when we update the block number, meaning we have to manually update the VAA again.
    // Not ideal long term, but hopefully we can switch back to the API when it's more stable.

    // function _getVaa(uint256 publishTime) internal returns (string memory) {
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
    // }

    function _getVaa() internal pure returns (string memory) {
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
