// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {DeploymentScript} from "./shared/DeploymentScript.s.sol";

import {Config} from "../../src/libraries/Config.sol";
import {ProxyOwnerDelays} from "../../src/libraries/ProxyOwnerDelays.sol";
import {AddressKeys} from "../../src/libraries/AddressKeys.sol";

import {IProxyOwner} from "../../src/interfaces/IProxyOwner.sol";
import {ILeveragedTokenFactory} from "../../src/interfaces/ILeveragedTokenFactory.sol";
import {IAddressProvider} from "../../src/interfaces/IAddressProvider.sol";

import {ProxyOwner} from "../../src/ProxyOwner.sol";

contract ProxyOwnerDeployment is DeploymentScript, Test {
    function _run() internal override {
        // Getting deployed contracts
        IAddressProvider addressProvider = IAddressProvider(
            _getDeployedAddress("AddressProvider")
        );

        // ProxyOwner Deployment
        ProxyOwner proxyOwner = new ProxyOwner();
        _deployedAddress("ProxyOwner", address(proxyOwner));

        // Transferring ownership
        addressProvider.updateAddress(AddressKeys.OWNER, address(proxyOwner));

        // Setting delays
        ProxyOwnerDelays.ProxyOwnerDelay[] memory delays_ = ProxyOwnerDelays
            .delays();
        for (uint256 i; i < delays_.length; i++) {
            bytes memory data_ = abi.encodeWithSelector(
                proxyOwner.setDelay.selector,
                delays_[i].selector,
                delays_[i].delay
            );
            IProxyOwner.Call[] memory calls_ = new IProxyOwner.Call[](1);
            calls_[0] = IProxyOwner.Call({
                target: address(proxyOwner),
                data: data_
            });
            uint256 id = proxyOwner.createProposal(calls_);
            proxyOwner.executeProposal(id);
        }

        // Transferring ownership of ProxyOwner to multisig
        proxyOwner.transferOwnership(Config.TEAM_MULTISIG);
    }

    function testProxyOwnerDeployment() public {
        IProxyOwner proxyOwner = IProxyOwner(_getDeployedAddress("ProxyOwner"));
        IAddressProvider addressProvider = IAddressProvider(
            _getDeployedAddress("AddressProvider")
        );

        assertEq(addressProvider.owner(), address(proxyOwner), "owner");

        assertEq(proxyOwner.delay(bytes4(0)), 0, "delays");
        ProxyOwnerDelays.ProxyOwnerDelay[] memory delays_ = ProxyOwnerDelays
            .delays();
        for (uint256 i; i < delays_.length; i++) {
            assertEq(
                proxyOwner.delay(delays_[i].selector),
                delays_[i].delay,
                "delays"
            );
        }
    }
}
