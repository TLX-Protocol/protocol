// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {Timelock} from "../src/Timelock.sol";
import {ITimelock} from "../src/interfaces/ITimelock.sol";

contract DummyContract {
    uint256 public state;

    function dummy(uint256 value_) public {
        state = value_;
    }

    function autoRevert() public pure {
        revert ITimelock.NotAuthorized();
    }
}

contract TimelockTest is Test {
    Timelock public timelock;

    address public dummyAccount = makeAddr("dummyAccount");
    address public dummyAddress;
    DummyContract public dummyContract;
    bytes public dummyData;
    bytes4 public dummySelector;

    function setUp() public {
        timelock = new Timelock();

        dummyContract = new DummyContract();
        dummyData = abi.encodeWithSelector(dummyContract.dummy.selector, 42);
        dummyAddress = address(dummyContract);
        dummySelector = dummyContract.dummy.selector;
    }

    function testInit() public {
        assertEq(timelock.allCalls().length, 0, "length");
        assertEq(timelock.pendingCalls().length, 0, "pendingCalls");
        assertEq(timelock.readyCalls().length, 0, "readyCalls");
    }

    function testPrepareRevertsForNonOwner() public {
        vm.prank(dummyAccount);
        vm.expectRevert();
        timelock.prepareCall(dummyAddress, dummyData);
    }

    function testPrepareCall() public {
        timelock.prepareCall(dummyAddress, dummyData);
        ITimelock.Call[] memory allCalls_ = timelock.allCalls();
        assertEq(allCalls_.length, 1, "length");
        assertEq(allCalls_[0].id, 0, "id");
        assertEq(allCalls_[0].ready, block.timestamp, "ready");
        assertEq(allCalls_[0].target, dummyAddress, "target");
        assertEq(allCalls_[0].data, dummyData, "data");
        assertEq(timelock.pendingCalls().length, 0, "pendingCalls");
        assertEq(timelock.readyCalls().length, 1, "readyCalls");
    }

    function testExecuteCall() public {
        timelock.prepareCall(dummyAddress, dummyData);
        timelock.executeCall(0);
        ITimelock.Call[] memory allCalls_ = timelock.allCalls();
        assertEq(dummyContract.state(), 42);
        assertEq(allCalls_.length, 0, "length");
        assertEq(timelock.pendingCalls().length, 0, "pendingCalls");
        assertEq(timelock.readyCalls().length, 0, "readyCalls");
    }

    function testExecuteCallRevertsForNonOwner() public {
        timelock.prepareCall(dummyAddress, dummyData);
        vm.prank(dummyAccount);
        vm.expectRevert();
        timelock.executeCall(0);
    }

    function testExecuteCallRevertsWhenAlreadyExecuted() public {
        timelock.prepareCall(dummyAddress, dummyData);
        timelock.executeCall(0);
        vm.expectRevert(
            abi.encodeWithSelector(ITimelock.CallDoesNotExist.selector, 0)
        );
        timelock.executeCall(0);
    }

    function testCancelCall() public {
        timelock.prepareCall(dummyAddress, dummyData);
        timelock.cancelCall(0);
        ITimelock.Call[] memory allCalls_ = timelock.allCalls();
        assertEq(allCalls_.length, 0, "length");
        assertEq(timelock.pendingCalls().length, 0, "pendingCalls");
        assertEq(timelock.readyCalls().length, 0, "readyCalls");
    }

    function testExecuteCallRevertsWhenCancelled() public {
        timelock.prepareCall(dummyAddress, dummyData);
        timelock.cancelCall(0);
        vm.expectRevert(
            abi.encodeWithSelector(ITimelock.CallDoesNotExist.selector, 0)
        );
        timelock.executeCall(0);
    }

    function testExecuteCallRevertsWhenReverts() public {
        bytes memory data_ = abi.encodeWithSelector(
            dummyContract.autoRevert.selector
        );
        timelock.prepareCall(dummyAddress, data_);
        vm.expectRevert();
        timelock.executeCall(0);
    }

    function testSetDelayRevertsForDirectCall() public {
        vm.expectRevert(ITimelock.NotAuthorized.selector);
        timelock.setDelay(dummySelector, 100);
    }

    function testSetDelay() public {
        bytes memory data_ = abi.encodeWithSelector(
            timelock.setDelay.selector,
            dummySelector,
            100
        );
        timelock.prepareCall(address(timelock), data_);
        timelock.executeCall(0);
        assertEq(timelock.delay(dummySelector), 100);
    }

    function testExecuteCallFailsWhenNotReady() public {
        bytes memory data_ = abi.encodeWithSelector(
            timelock.setDelay.selector,
            dummySelector,
            1 days
        );
        timelock.prepareCall(address(timelock), data_);
        timelock.executeCall(0);
        timelock.prepareCall(dummyAddress, dummyData);
        vm.expectRevert(
            abi.encodeWithSelector(ITimelock.CallNotReady.selector, 1)
        );
        timelock.executeCall(1);
    }

    function testExecuteAfterDelay() public {
        bytes memory data_ = abi.encodeWithSelector(
            timelock.setDelay.selector,
            dummySelector,
            1 days
        );
        timelock.prepareCall(address(timelock), data_);
        timelock.executeCall(0);
        timelock.prepareCall(dummyAddress, dummyData);
        skip(1 days);
        timelock.executeCall(1);
        assertEq(dummyContract.state(), 42);
    }

    function testCancelCallRevertsWhenAlreadyCancelled() public {
        timelock.prepareCall(dummyAddress, dummyData);
        timelock.cancelCall(0);
        vm.expectRevert(
            abi.encodeWithSelector(ITimelock.CallDoesNotExist.selector, 0)
        );
        timelock.cancelCall(0);
    }

    function testCancelCallRevertsWhenAlreadyExecuted() public {
        timelock.prepareCall(dummyAddress, dummyData);
        timelock.executeCall(0);
        vm.expectRevert(
            abi.encodeWithSelector(ITimelock.CallDoesNotExist.selector, 0)
        );
        timelock.cancelCall(0);
    }

    function testRevetsWhenCreatingCallWithZeroAddress() public {
        vm.expectRevert(ITimelock.InvalidTarget.selector);
        timelock.prepareCall(address(0), dummyData);
    }
}
