// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {DeploymentScript} from "./shared/DeploymentScript.s.sol";

import {Config} from "../../src/libraries/Config.sol";
import {TimelockDelays} from "../../src/libraries/TimelockDelays.sol";
import {AddressKeys} from "../../src/libraries/AddressKeys.sol";

import {ITimelock} from "../../src/interfaces/ITimelock.sol";
import {ILeveragedTokenFactory} from "../../src/interfaces/ILeveragedTokenFactory.sol";
import {IAddressProvider} from "../../src/interfaces/IAddressProvider.sol";

import {Timelock} from "../../src/Timelock.sol";

contract TimelockDeployment is DeploymentScript, Test {
    function _run() internal override {
        // Getting deployed contracts
        IAddressProvider addressProvider = IAddressProvider(
            _getDeployedAddress("AddressProvider")
        );

        // Timelock Deployment
        Timelock timelock = new Timelock();
        _deployedAddress("Timelock", address(timelock));

        // Transferring ownership
        addressProvider.updateAddress(AddressKeys.OWNER, address(timelock));

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
        timelock.transferOwnership(Config.TEAM_MULTISIG);
    }

    function testTimelockDeployment() public {
        ITimelock timelock = ITimelock(_getDeployedAddress("Timelock"));
        IAddressProvider addressProvider = IAddressProvider(
            _getDeployedAddress("AddressProvider")
        );

        assertEq(addressProvider.owner(), address(timelock), "owner");

        assertEq(timelock.delay(bytes4(0)), 0, "delays");
        TimelockDelays.TimelockDelay[] memory delays_ = TimelockDelays.delays();
        for (uint256 i; i < delays_.length; i++) {
            assertEq(
                timelock.delay(delays_[i].selector),
                delays_[i].delay,
                "delays"
            );
        }
    }
}
