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

    function _makeCalls(
        address target,
        bytes memory data,
        uint256 n
    ) internal pure returns (ITimelock.Call[] memory) {
        ITimelock.Call[] memory calls_ = new ITimelock.Call[](n);
        for (uint256 i; i < n; i++)
            calls_[i] = ITimelock.Call({target: target, data: data});
        return calls_;
    }

    function testInit() public {
        assertEq(timelock.allProposals().length, 0, "length");
        assertEq(timelock.pendingProposals().length, 0, "pendingProposals");
        assertEq(timelock.readyProposals().length, 0, "readyProposals");
    }

    function testPrepareRevertsForNonOwner() public {
        vm.prank(dummyAccount);
        vm.expectRevert();
        timelock.createProposal(_makeCalls(dummyAddress, dummyData, 1));
    }

    function testPrepareProposal() public {
        timelock.createProposal(_makeCalls(dummyAddress, dummyData, 2));

        ITimelock.Proposal[] memory allProposals = timelock.allProposals();
        assertEq(allProposals[0].id, 0, "id");
        assertEq(allProposals[0].ready, block.timestamp, "ready");

        ITimelock.Call[] memory proposalCalls = allProposals[0].calls;
        assertEq(proposalCalls.length, 2, "length");
        assertEq(proposalCalls[0].target, dummyAddress, "target");
        assertEq(proposalCalls[0].data, dummyData, "data");

        assertEq(timelock.pendingProposals().length, 0, "pendingProposals");
        assertEq(timelock.readyProposals().length, 1, "readyProposals");
    }

    function testPrepareProposalDifferentDelays() public {
        // set dummySelector delay to 100 and autoRevert to 200
        for (uint256 i; i < 2; i++) {
            bytes memory data_ = abi.encodeWithSelector(
                timelock.setDelay.selector,
                i == 0 ? dummySelector : dummyContract.autoRevert.selector,
                i == 0 ? 100 : 200
            );
            uint256 id = timelock.createProposal(
                _makeCalls(address(timelock), data_, 1)
            );
            timelock.executeProposal(id);
        }

        ITimelock.Call[] memory calls_ = new ITimelock.Call[](2);
        calls_[0] = ITimelock.Call({target: dummyAddress, data: dummyData});
        calls_[1] = ITimelock.Call({
            target: dummyAddress,
            data: abi.encodeWithSelector(dummyContract.autoRevert.selector)
        });
        timelock.createProposal(calls_);

        ITimelock.Proposal[] memory allProposals = timelock.allProposals();
        assertEq(allProposals[0].ready, block.timestamp + 200, "ready");
    }

    function testExecuteProposal() public {
        timelock.createProposal(_makeCalls(dummyAddress, dummyData, 2));
        timelock.executeProposal(0);
        assertEq(dummyContract.state(), 42);
        assertEq(timelock.allProposals().length, 0, "length");
        assertEq(timelock.pendingProposals().length, 0, "pendingProposals");
        assertEq(timelock.readyProposals().length, 0, "readyProposals");
    }

    function testExecuteProposalRevertsForNonOwner() public {
        timelock.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        vm.prank(dummyAccount);
        vm.expectRevert();
        timelock.executeProposal(0);
    }

    function testExecuteProposalRevertsWhenAlreadyExecuted() public {
        timelock.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        timelock.executeProposal(0);
        vm.expectRevert(
            abi.encodeWithSelector(ITimelock.ProposalDoesNotExist.selector, 0)
        );
        timelock.executeProposal(0);
    }

    function testCancelProposal() public {
        timelock.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        timelock.cancelProposal(0);
        assertEq(timelock.allProposals().length, 0, "length");
        assertEq(timelock.pendingProposals().length, 0, "pendingProposals");
        assertEq(timelock.readyProposals().length, 0, "readyProposals");
    }

    function testExecuteCallRevertsWhenCancelled() public {
        timelock.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        timelock.cancelProposal(0);
        vm.expectRevert(
            abi.encodeWithSelector(ITimelock.ProposalDoesNotExist.selector, 0)
        );
        timelock.executeProposal(0);
    }

    function testExecuteCallRevertsWhenReverts() public {
        bytes memory data_ = abi.encodeWithSelector(
            dummyContract.autoRevert.selector
        );
        timelock.createProposal(_makeCalls(dummyAddress, data_, 1));
        vm.expectRevert();
        timelock.executeProposal(0);
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
        timelock.createProposal(_makeCalls(address(timelock), data_, 1));
        timelock.executeProposal(0);
        assertEq(timelock.delay(dummySelector), 100);
    }

    function testExecuteCallFailsWhenNotReady() public {
        bytes memory data_ = abi.encodeWithSelector(
            timelock.setDelay.selector,
            dummySelector,
            1 days
        );
        timelock.createProposal(_makeCalls(address(timelock), data_, 1));
        timelock.executeProposal(0);
        timelock.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        vm.expectRevert(
            abi.encodeWithSelector(ITimelock.ProposalNotReady.selector, 1)
        );
        timelock.executeProposal(1);
    }

    function testExecuteAfterDelay() public {
        bytes memory data_ = abi.encodeWithSelector(
            timelock.setDelay.selector,
            dummySelector,
            1 days
        );
        timelock.createProposal(_makeCalls(address(timelock), data_, 1));
        timelock.executeProposal(0);
        timelock.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        skip(1 days);
        timelock.executeProposal(1);
        assertEq(dummyContract.state(), 42);
    }

    function testCancelCallRevertsWhenAlreadyCancelled() public {
        timelock.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        timelock.cancelProposal(0);
        vm.expectRevert(
            abi.encodeWithSelector(ITimelock.ProposalDoesNotExist.selector, 0)
        );
        timelock.cancelProposal(0);
    }

    function testCancelProposalRevertsWhenAlreadyExecuted() public {
        timelock.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        timelock.executeProposal(0);
        vm.expectRevert(
            abi.encodeWithSelector(ITimelock.ProposalDoesNotExist.selector, 0)
        );
        timelock.cancelProposal(0);
    }

    function testRevertsWhenCreatingProposalWithZeroAddress() public {
        vm.expectRevert(ITimelock.InvalidTarget.selector);
        timelock.createProposal(_makeCalls(address(0), dummyData, 1));
    }
}
