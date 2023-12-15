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

    string[] public lines = new string[](1000);
    uint256 public lineCount;

    function run() external {
        uint256 deployerPrivateKey_ = vm.envOr("PRIVATE_KEY", uint256(0));
        if (deployerPrivateKey_ == 0) vm.startBroadcast(Config.BINANCE);
        else vm.startBroadcast(deployerPrivateKey_);
        _loadLines();

        _run();

        vm.stopBroadcast();
    }

    function _run() internal virtual;

    function _deployedAddress(string memory name, address addr) internal {
        _writeDeployedAddress(name, addr);
        console.log("%s: %s", name, Strings.toHexString(uint160(addr), 20));
    }

    function _loadLines() internal {
        lineCount = 0;
        while (true) {
            string memory line = vm.readLine(DEPLOYMENTS_PATH);
            string memory empty = "";
            if (
                keccak256(abi.encodePacked(line)) ==
                keccak256(abi.encodePacked(empty))
            ) break;
            lines[lineCount] = line;
            lineCount++;
        }
        if (lineCount == 1) {
            lines[0] = "{";
            lines[1] = "}";
            lineCount = 2;
        }
    }

    function _writeDeployedAddress(string memory name, address addr) internal {
        string memory newLine = string.concat(
            '"',
            name,
            '": "',
            Strings.toHexString(uint160(addr), 20),
            '"'
        );
        if (lineCount != 2) {
            newLine = string.concat(",", newLine);
        }
        lines[lineCount - 1] = newLine;
        lines[lineCount] = "}";
        lineCount++;

        vm.writeFile(DEPLOYMENTS_PATH, "");
        for (uint256 i; i < lineCount; i++) {
            vm.writeLine(DEPLOYMENTS_PATH, lines[i]);
        }
    }

    function _getDeployedAddress(
        string memory name
    ) internal view returns (address) {
        string memory json = vm.readFile(DEPLOYMENTS_PATH);
        string memory value = string.concat(".", name);
        return abi.decode(json.parseRaw(value), (address));
    }
}
