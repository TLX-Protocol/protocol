// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Test.sol";

library Expectations {
    function expectRevertWith(Vm vm, bytes4 selector, bytes32 arg0) internal {
        bytes memory expectedError = abi.encodeWithSelector(selector, arg0);
        vm.expectRevert(expectedError);
    }
}
