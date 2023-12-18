// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/StdJson.sol";

import {stdStorage, StdStorage} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {Config} from "../../../src/libraries/Config.sol";
import {Tokens} from "../../../src/libraries/Tokens.sol";

abstract contract DeploymentScript is Script {
    using stdStorage for StdStorage;
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
}
