// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {DeploymentScript} from "./shared/DeploymentScript.s.sol";

import {Config} from "../../src/libraries/Config.sol";
import {TimelockDelays} from "../../src/libraries/TimelockDelays.sol";

import {IOwnable} from "../../src/interfaces/libraries/IOwnable.sol";
import {ITimelock} from "../../src/interfaces/ITimelock.sol";

import {Timelock} from "../../src/Timelock.sol";

contract TimelockDeployment is DeploymentScript {
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
        IOwnable locker = IOwnable(_getDeployedAddress("Locker"));
        IOwnable parameterProvider = IOwnable(
            _getDeployedAddress("ParameterProvider")
        );
        IOwnable referrals = IOwnable(_getDeployedAddress("Referrals"));

        // Timelock Deployment
        Timelock timelock = new Timelock();
        _deployedAddress("Timelock", address(timelock));

        // Transferring ownership
        addressProvider.transferOwnership(address(timelock));
        airdrop.transferOwnership(address(timelock));
        bonding.transferOwnership(address(timelock));
        leveragedTokenFactory.transferOwnership(address(timelock));
        locker.transferOwnership(address(timelock));
        parameterProvider.transferOwnership(address(timelock));
        referrals.transferOwnership(address(timelock));

        // Setting delays
        TimelockDelays.TimelockDelay[] memory delays_ = TimelockDelays.delays();
        for (uint256 i; i < delays_.length; i++) {
            bytes memory data_ = abi.encodeWithSelector(
                timelock.setDelay.selector,
                delays_[i].selector,
                delays_[i].delay
            );
            ITimelock.Call[] memory calls_ = new ITimelock.Call[](1);
            calls_[0] = ITimelock.Call({
                target: address(timelock),
                data: data_
            });
            uint256 id = timelock.createProposal(calls_);
            timelock.executeProposal(id);
        }

        // Transferring ownership of Timelock to multisig
        timelock.transferOwnership(Config.TREASURY);
    }
}
