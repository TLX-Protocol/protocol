// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {DeploymentScript} from "./shared/DeploymentScript.s.sol";

import {Config} from "../../src/libraries/Config.sol";
import {TimelockDelays} from "../../src/libraries/TimelockDelays.sol";

import {IOwnable} from "../../src/interfaces/libraries/IOwnable.sol";
import {ITimelock} from "../../src/interfaces/ITimelock.sol";

import {Timelock} from "../../src/Timelock.sol";

contract TimelockDeployment is DeploymentScript, Test {
    function _run() internal override {
        // Getting deployed contracts
        IOwnable addressProvider = IOwnable(
            _getDeployedAddress("AddressProvider")
        );
        IOwnable airdrop = IOwnable(_getDeployedAddress("Airdrop"));
        IOwnable bonding = IOwnable(_getDeployedAddress("Bonding"));
        IOwnable leveragedTokenFactory = IOwnable(
            _getDeployedAddress("LeveragedTokenFactory")
        );
        IOwnable staker = IOwnable(_getDeployedAddress("Staker"));
        IOwnable parameterProvider = IOwnable(
            _getDeployedAddress("ParameterProvider")
        );
        IOwnable referrals = IOwnable(_getDeployedAddress("Referrals"));

        // Timelock Deployment
        Timelock Timelock = new Timelock();
        _deployedAddress("Timelock", address(Timelock));

        // Transferring ownership
        addressProvider.transferOwnership(address(Timelock));
        airdrop.transferOwnership(address(Timelock));
        bonding.transferOwnership(address(Timelock));
        leveragedTokenFactory.transferOwnership(address(Timelock));
        staker.transferOwnership(address(Timelock));
        parameterProvider.transferOwnership(address(Timelock));
        referrals.transferOwnership(address(Timelock));

        // Setting delays
        TimelockDelays.TimelockDelay[] memory delays_ = TimelockDelays.delays();
        for (uint256 i; i < delays_.length; i++) {
            bytes memory data_ = abi.encodeWithSelector(
                Timelock.setDelay.selector,
                delays_[i].selector,
                delays_[i].delay
            );
            ITimelock.Call[] memory calls_ = new ITimelock.Call[](1);
            calls_[0] = ITimelock.Call({
                target: address(Timelock),
                data: data_
            });
            uint256 id = Timelock.createProposal(calls_);
            Timelock.executeProposal(id);
        }

        // Transferring ownership of Timelock to multisig
        Timelock.transferOwnership(Config.TREASURY);
    }

    function testTimelockDeployment() public {
        ITimelock Timelock = ITimelock(_getDeployedAddress("Timelock"));
        IOwnable addressProvider = IOwnable(
            _getDeployedAddress("AddressProvider")
        );
        IOwnable airdrop = IOwnable(_getDeployedAddress("Airdrop"));
        IOwnable bonding = IOwnable(_getDeployedAddress("Bonding"));
        IOwnable leveragedTokenFactory = IOwnable(
            _getDeployedAddress("LeveragedTokenFactory")
        );
        IOwnable staker = IOwnable(_getDeployedAddress("Staker"));
        IOwnable parameterProvider = IOwnable(
            _getDeployedAddress("ParameterProvider")
        );
        IOwnable referrals = IOwnable(_getDeployedAddress("Referrals"));

        assertEq(addressProvider.owner(), address(Timelock), "addressProvider");
        assertEq(airdrop.owner(), address(Timelock), "airdrop");
        assertEq(bonding.owner(), address(Timelock), "bonding");
        assertEq(
            leveragedTokenFactory.owner(),
            address(Timelock),
            "leveragedTokenFactory"
        );
        assertEq(staker.owner(), address(Timelock), "staker");
        assertEq(
            parameterProvider.owner(),
            address(Timelock),
            "parameterProvider"
        );
        assertEq(referrals.owner(), address(Timelock), "referrals");
        assertEq(Timelock.delay(bytes4(0)), 0, "delays");

        TimelockDelays.TimelockDelay[] memory delays_ = TimelockDelays.delays();
        for (uint256 i; i < delays_.length; i++) {
            assertEq(
                Timelock.delay(delays_[i].selector),
                delays_[i].delay,
                "delays"
            );
        }
    }
}
