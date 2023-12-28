// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {DeploymentScript} from "./shared/DeploymentScript.s.sol";

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {AddressKeys} from "../../src/libraries/AddressKeys.sol";
import {ParameterKeys} from "../../src/libraries/ParameterKeys.sol";
import {Config} from "../../src/libraries/Config.sol";
import {Vestings} from "../../src/libraries/Vestings.sol";

import {AddressProvider} from "../../src/AddressProvider.sol";
import {ParameterProvider} from "../../src/ParameterProvider.sol";
import {TlxToken} from "../../src/TlxToken.sol";
import {Airdrop} from "../../src/Airdrop.sol";
import {Locker} from "../../src/Locker.sol";
import {Bonding} from "../../src/Bonding.sol";
import {Vesting} from "../../src/Vesting.sol";

import {IAddressProvider} from "../../src/interfaces/IAddressProvider.sol";

contract TokenomicsDeployment is DeploymentScript, Test {
    function _run() internal override {
        // AddressProvider Deployment
        AddressProvider addressProvider = new AddressProvider();
        _deployedAddress("AddressProvider", address(addressProvider));
        addressProvider.updateAddress(AddressKeys.TREASURY, Config.TREASURY);
        addressProvider.updateAddress(
            AddressKeys.BASE_ASSET,
            Config.BASE_ASSET
        );
        addressProvider.updateAddress(
            AddressKeys.REBALANCE_FEE_RECEIVER,
            Config.REBALANCE_FEE_RECEIVER
        );

        // ParameterProvider Deployment
        ParameterProvider parameterProvider = new ParameterProvider(
            address(addressProvider)
        );
        _deployedAddress("ParameterProvider", address(parameterProvider));
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

        // Vesting Deployment
        Vesting vesting = new Vesting(
            address(addressProvider),
            Config.VESTING_DURATION,
            Vestings.vestings()
        );
        _deployedAddress("Vesting", address(vesting));
        addressProvider.updateAddress(AddressKeys.VESTING, address(vesting));

        // Bonding Deployment
        Bonding bonding = new Bonding(
            address(addressProvider),
            Config.INITIAL_TLX_PER_SECOND,
            Config.PERIOD_DECAY_MULTIPLIER,
            Config.PERIOD_DURATION,
            Config.BASE_FOR_ALL_TLX
        );
        _deployedAddress("Bonding", address(bonding));
        addressProvider.updateAddress(AddressKeys.BONDING, address(bonding));
        addressProvider.updateAddress(AddressKeys.POL, Config.POL);

        // Airdrop Deployment
        Airdrop airdrop = new Airdrop(
            address(addressProvider),
            bytes32(0),
            block.timestamp + Config.AIRDROP_CLAIM_PERIOD,
            Config.AIRDROP_AMOUNT
        );
        _deployedAddress("Airdrop", address(airdrop));
        airdrop.updateMerkleRoot(Config.MERKLE_ROOT);
        addressProvider.updateAddress(AddressKeys.AIRDROP, address(airdrop));

        // Locker Deployment
        Locker locker = new Locker(
            address(addressProvider),
            Config.LOCKER_UNLOCK_DELAY,
            Config.BASE_ASSET
        );
        _deployedAddress("Locker", address(locker));
        addressProvider.updateAddress(AddressKeys.LOCKER, address(locker));

        // TLX Token Deployment
        TlxToken tlx = new TlxToken(
            Config.TOKEN_NAME,
            Config.TOKEN_SYMBOL,
            address(addressProvider),
            Config.AIRDROP_AMOUNT,
            Config.BONDING_AMOUNT,
            Config.TREASURY_AMOUNT,
            Config.VESTING_AMOUNT
        );
        _deployedAddress("TLX", address(tlx));
        addressProvider.updateAddress(AddressKeys.TLX, address(tlx));
    }

    function testTokenomicsDeployment() public {
        IAddressProvider addressProvider = IAddressProvider(
            _getDeployedAddress("AddressProvider")
        );
        address teamMember = Vestings.vestings()[0].account;
        vm.startPrank(teamMember);

        skip(10 days);
        assertEq(
            addressProvider.tlx().balanceOf(teamMember),
            0,
            "tlx balance starts at 0"
        );
        addressProvider.vesting().claim();
        uint256 tlxBalance = addressProvider.tlx().balanceOf(teamMember);
        assertGt(tlxBalance, 0, "greater than 0");
        uint256 lockAmount = tlxBalance / 2;
        addressProvider.tlx().approve(
            address(addressProvider.locker()),
            lockAmount
        );
        addressProvider.locker().lock(lockAmount);
        assertEq(
            addressProvider.tlx().balanceOf(address(addressProvider.locker())),
            lockAmount,
            "locker balance goes up"
        );
        assertEq(
            addressProvider.tlx().balanceOf(teamMember),
            lockAmount,
            "tlx balance goes down"
        );
        addressProvider.locker().prepareUnlock();
        skip(Config.LOCKER_UNLOCK_DELAY);
        addressProvider.locker().unlock();
        assertEq(
            addressProvider.tlx().balanceOf(address(addressProvider.locker())),
            0,
            "locker balance goes down"
        );
        assertEq(
            addressProvider.tlx().balanceOf(teamMember),
            tlxBalance,
            "tlx balance goes up"
        );
    }
}