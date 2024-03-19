// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {Errors} from "../src/libraries/Errors.sol";

import {ProxyOwner} from "../src/ProxyOwner.sol";
import {IProxyOwner} from "../src/interfaces/IProxyOwner.sol";

contract DummyContract {
    uint256 public state;

    function dummy(uint256 value_) public {
        state = value_;
    }

    function autoRevert() public pure {
        revert Errors.NotAuthorized();
    }
}

contract ProxyOwnerTest is Test {
    ProxyOwner public proxyOwner;

    address public dummyAccount = makeAddr("dummyAccount");
    address public dummyAddress;
    DummyContract public dummyContract;
    bytes public dummyData;
    bytes4 public dummySelector;

    function setUp() public {
        proxyOwner = new ProxyOwner();

        dummyContract = new DummyContract();
        dummyData = abi.encodeWithSelector(dummyContract.dummy.selector, 42);
        dummyAddress = address(dummyContract);
        dummySelector = dummyContract.dummy.selector;
    }

    function _makeCalls(
        address target,
        bytes memory data,
        uint256 n
    ) internal pure returns (IProxyOwner.Call[] memory) {
        IProxyOwner.Call[] memory calls_ = new IProxyOwner.Call[](n);
        for (uint256 i; i < n; i++)
            calls_[i] = IProxyOwner.Call({target: target, data: data});
        return calls_;
    }

    function testInit() public {
        assertEq(proxyOwner.allProposals().length, 0, "length");
        assertEq(proxyOwner.pendingProposals().length, 0, "pendingProposals");
        assertEq(proxyOwner.readyProposals().length, 0, "readyProposals");
    }

    function testPrepareRevertsForNonOwner() public {
        vm.prank(dummyAccount);
        vm.expectRevert();
        proxyOwner.createProposal(_makeCalls(dummyAddress, dummyData, 1));
    }

    function testPrepareProposal() public {
        proxyOwner.createProposal(_makeCalls(dummyAddress, dummyData, 2));

        IProxyOwner.Proposal[] memory allProposals = proxyOwner.allProposals();
        assertEq(allProposals[0].id, 0, "id");
        assertEq(allProposals[0].ready, block.timestamp, "ready");

        IProxyOwner.Call[] memory proposalCalls = allProposals[0].calls;
        assertEq(proposalCalls.length, 2, "length");
        assertEq(proposalCalls[0].target, dummyAddress, "target");
        assertEq(proposalCalls[0].data, dummyData, "data");

        assertEq(proxyOwner.pendingProposals().length, 0, "pendingProposals");
        assertEq(proxyOwner.readyProposals().length, 1, "readyProposals");
    }

    function testPrepareProposalDifferentDelays() public {
        // set dummySelector delay to 100 and autoRevert to 200
        for (uint256 i; i < 2; i++) {
            bytes memory data_ = abi.encodeWithSelector(
                proxyOwner.setDelay.selector,
                i == 0 ? dummySelector : dummyContract.autoRevert.selector,
                i == 0 ? 100 : 200
            );
            uint256 id = proxyOwner.createProposal(
                _makeCalls(address(proxyOwner), data_, 1)
            );
            proxyOwner.executeProposal(id);
        }

        IProxyOwner.Call[] memory calls_ = new IProxyOwner.Call[](2);
        calls_[0] = IProxyOwner.Call({target: dummyAddress, data: dummyData});
        calls_[1] = IProxyOwner.Call({
            target: dummyAddress,
            data: abi.encodeWithSelector(dummyContract.autoRevert.selector)
        });
        proxyOwner.createProposal(calls_);

        IProxyOwner.Proposal[] memory allProposals = proxyOwner.allProposals();
        assertEq(allProposals[0].ready, block.timestamp + 200, "ready");
    }

    function testExecuteProposal() public {
        proxyOwner.createProposal(_makeCalls(dummyAddress, dummyData, 2));
        proxyOwner.executeProposal(0);
        assertEq(dummyContract.state(), 42);
        assertEq(proxyOwner.allProposals().length, 0, "length");
        assertEq(proxyOwner.pendingProposals().length, 0, "pendingProposals");
        assertEq(proxyOwner.readyProposals().length, 0, "readyProposals");
    }

    function testExecuteProposalRevertsForNonOwner() public {
        proxyOwner.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        vm.prank(dummyAccount);
        vm.expectRevert();
        proxyOwner.executeProposal(0);
    }

    function testExecuteProposalRevertsWhenAlreadyExecuted() public {
        proxyOwner.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        proxyOwner.executeProposal(0);
        vm.expectRevert(
            abi.encodeWithSelector(IProxyOwner.ProposalDoesNotExist.selector, 0)
        );
        proxyOwner.executeProposal(0);
    }

    function testCancelProposal() public {
        proxyOwner.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        proxyOwner.cancelProposal(0);
        assertEq(proxyOwner.allProposals().length, 0, "length");
        assertEq(proxyOwner.pendingProposals().length, 0, "pendingProposals");
        assertEq(proxyOwner.readyProposals().length, 0, "readyProposals");
    }

    function testExecuteCallRevertsWhenCancelled() public {
        proxyOwner.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        proxyOwner.cancelProposal(0);
        vm.expectRevert(
            abi.encodeWithSelector(IProxyOwner.ProposalDoesNotExist.selector, 0)
        );
        proxyOwner.executeProposal(0);
    }

    function testExecuteCallRevertsWhenReverts() public {
        bytes memory data_ = abi.encodeWithSelector(
            dummyContract.autoRevert.selector
        );
        proxyOwner.createProposal(_makeCalls(dummyAddress, data_, 1));
        vm.expectRevert();
        proxyOwner.executeProposal(0);
    }

    function testSetDelayRevertsForDirectCall() public {
        vm.expectRevert(Errors.NotAuthorized.selector);
        proxyOwner.setDelay(dummySelector, 100);
    }

    function testSetDelay() public {
        bytes memory data_ = abi.encodeWithSelector(
            proxyOwner.setDelay.selector,
            dummySelector,
            100
        );
        proxyOwner.createProposal(_makeCalls(address(proxyOwner), data_, 1));
        proxyOwner.executeProposal(0);
        assertEq(proxyOwner.delay(dummySelector), 100);
    }

    function testExecuteCallFailsWhenNotReady() public {
        bytes memory data_ = abi.encodeWithSelector(
            proxyOwner.setDelay.selector,
            dummySelector,
            1 days
        );
        proxyOwner.createProposal(_makeCalls(address(proxyOwner), data_, 1));
        proxyOwner.executeProposal(0);
        proxyOwner.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        vm.expectRevert(
            abi.encodeWithSelector(IProxyOwner.ProposalNotReady.selector, 1)
        );
        proxyOwner.executeProposal(1);
    }

    function testExecuteAfterDelay() public {
        bytes memory data_ = abi.encodeWithSelector(
            proxyOwner.setDelay.selector,
            dummySelector,
            1 days
        );
        proxyOwner.createProposal(_makeCalls(address(proxyOwner), data_, 1));
        proxyOwner.executeProposal(0);
        proxyOwner.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        skip(1 days);
        proxyOwner.executeProposal(1);
        assertEq(dummyContract.state(), 42);
    }

    function testCancelCallRevertsWhenAlreadyCancelled() public {
        proxyOwner.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        proxyOwner.cancelProposal(0);
        vm.expectRevert(
            abi.encodeWithSelector(IProxyOwner.ProposalDoesNotExist.selector, 0)
        );
        proxyOwner.cancelProposal(0);
    }

    function testCancelProposalRevertsWhenAlreadyExecuted() public {
        proxyOwner.createProposal(_makeCalls(dummyAddress, dummyData, 1));
        proxyOwner.executeProposal(0);
        vm.expectRevert(
            abi.encodeWithSelector(IProxyOwner.ProposalDoesNotExist.selector, 0)
        );
        proxyOwner.cancelProposal(0);
    }

    function testRevertsWhenCreatingProposalWithZeroAddress() public {
        vm.expectRevert(IProxyOwner.InvalidTarget.selector);
        proxyOwner.createProposal(_makeCalls(address(0), dummyData, 1));
    }
}
