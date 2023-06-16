// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

contract IntegrationTest is Test {
    constructor() {
        vm.selectFork(vm.createFork(vm.envString("RPC"), 17_491_596));
    }
}
