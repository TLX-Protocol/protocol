// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/StdJson.sol";

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {Config} from "../../../src/libraries/Config.sol";

abstract contract DeploymentScript is Script {
    using stdJson for string;

    string public constant DEPLOYMENTS_PATH = "deployments.json";

    function run() external {
        uint256 deployerPrivateKey_ = vm.envOr("PRIVATE_KEY", uint256(0));
        if (deployerPrivateKey_ == 0) vm.startBroadcast(Config.BINANCE);
        else vm.startBroadcast(deployerPrivateKey_);
        _run();

        vm.stopBroadcast();
    }

    function _run() internal virtual;

    function _deployedAddress(string memory name, address addr) internal {
        _writeDeployedAddress(name, addr);
        console.log("%s: %s", name, Strings.toHexString(uint160(addr), 20));
    }

    function _writeDeployedAddress(string memory name, address addr) internal {
        if (vm.isFile(DEPLOYMENTS_PATH)) {
            vm.serializeJson("contracts", vm.readFile(DEPLOYMENTS_PATH));
        }
        string memory newJson = vm.serializeAddress("contracts", name, addr);
        vm.writeJson(newJson, DEPLOYMENTS_PATH);
    }

    function _getDeployedAddress(
        string memory name
    ) internal view returns (address) {
        string memory json = vm.readFile(DEPLOYMENTS_PATH);
        string memory key = string.concat(".", name);
        return json.readAddress(key);
    }
}
