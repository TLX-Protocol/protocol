// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Tokens} from "../../src/libraries/Tokens.sol";
import {Contracts} from "../../src/libraries/Contracts.sol";
import {AddressKeys} from "../../src/libraries/AddressKeys.sol";
import {Config} from "../../src/libraries/Config.sol";

import {IVesting} from "../../src/interfaces/IVesting.sol";

import {ChainlinkOracle} from "../../src/ChainlinkOracle.sol";
import {MockOracle} from "../../src/testing/MockOracle.sol";
import {LeveragedTokenFactory} from "../../src/LeveragedTokenFactory.sol";
import {AddressProvider} from "../../src/AddressProvider.sol";
import {PositionManagerFactory} from "../../src/PositionManagerFactory.sol";
import {TlxToken} from "../../src/TlxToken.sol";
import {Airdrop} from "../../src/Airdrop.sol";
import {Locker} from "../../src/Locker.sol";
import {Bonding} from "../../src/Bonding.sol";
import {Vesting} from "../../src/Vesting.sol";

contract IntegrationTest is Test {
    using stdStorage for StdStorage;

    // Users
    address public alice = 0xEcfcf2996C7c2908Fc050f5EAec633c01A937712;
    address public bob = 0x787626366D8a4B8a0175ea011EdBE25e77290Dd1;
    address public gmxVault = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public treasury = makeAddr("treasury");

    // Contracts
    ChainlinkOracle public chainlinkOracle;
    MockOracle public mockOracle;
    LeveragedTokenFactory public leveragedTokenFactory;
    AddressProvider public addressProvider;
    PositionManagerFactory public positionManagerFactory;
    TlxToken public tlx;
    Airdrop public airdrop;
    Locker public locker;
    Bonding public bonding;
    Vesting public vesting;

    constructor() {
        vm.selectFork(vm.createFork(vm.envString("RPC"), 17_491_596));

        // AddressProvider Setup
        addressProvider = new AddressProvider();
        addressProvider.updateAddress(AddressKeys.TREASURY, treasury);
        addressProvider.updateAddress(AddressKeys.BASE_ASSET, Tokens.USDC);

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

        // Chainlink Oracle Setup
        chainlinkOracle = new ChainlinkOracle(
            address(addressProvider),
            Contracts.ETH_USD_ORACLE
        );
        chainlinkOracle.setUsdOracle(Tokens.UNI, Contracts.UNI_USD_ORACLE);
        chainlinkOracle.setUsdOracle(address(0), Contracts.ETH_USD_ORACLE);
        chainlinkOracle.setUsdOracle(Tokens.USDC, Contracts.USDC_USD_ORACLE);
        chainlinkOracle.setEthOracle(Tokens.WBTC, Contracts.WBTC_ETH_ORACLE);
        addressProvider.updateAddress(
            AddressKeys.ORACLE,
            address(chainlinkOracle)
        );

        // LeveragedTokenFactory Setup
        leveragedTokenFactory = new LeveragedTokenFactory(
            address(addressProvider),
            Config.MAX_LEVERAGE
        );
        addressProvider.updateAddress(
            AddressKeys.LEVERAGED_TOKEN_FACTORY,
            address(leveragedTokenFactory)
        );

        // PositionManagerFactory Setup
        positionManagerFactory = new PositionManagerFactory(
            address(addressProvider)
        );
        addressProvider.updateAddress(
            AddressKeys.POSITION_MANAGER_FACTORY,
            address(positionManagerFactory)
        );

        // TLX Token Setup
        tlx = new TlxToken(address(addressProvider));
        addressProvider.updateAddress(AddressKeys.TLX, address(tlx));

        // Airdrop Setup
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = keccak256(abi.encodePacked(alice, uint256(100e18)));
        leaves[1] = keccak256(abi.encodePacked(bob, uint256(200e18)));
        airdrop = new Airdrop(
            address(addressProvider),
            bytes32(0),
            block.timestamp + Config.AIRDROP_CLAIM_PERIOD,
            Config.AIRDRIP_AMOUNT
        );
        addressProvider.updateAddress(AddressKeys.AIRDROP, address(airdrop));

        // Locker Setup
        locker = new Locker(
            address(addressProvider),
            Config.LOCKER_UNLOCK_DELAY,
            Config.REWARD_TOKEN
        );
        addressProvider.updateAddress(AddressKeys.LOCKER, address(locker));

        // Mock Oracle Setup
        mockOracle = new MockOracle();
        uint256 uniPrice_ = chainlinkOracle.getUsdPrice(Tokens.UNI);
        mockOracle.setPrice(Tokens.UNI, uniPrice_);
        uint256 ethPrice_ = chainlinkOracle.getUsdPrice(address(0));
        mockOracle.setPrice(address(0), ethPrice_);
        uint256 usdcPrice_ = chainlinkOracle.getUsdPrice(Tokens.USDC);
        mockOracle.setPrice(Tokens.USDC, usdcPrice_);
    }

    function _mintTokensFor(
        address token_,
        address account_,
        uint256 amount_
    ) internal {
        stdstore
            .target(token_)
            .sig(IERC20(token_).balanceOf.selector)
            .with_key(account_)
            .checked_write(amount_);
    }
}
