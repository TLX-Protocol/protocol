// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import {ITimelock} from "./interfaces/ITimelock.sol";

contract Timelock is ITimelock, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(bytes4 => uint256) internal _delays;
    uint256 internal _nextProposalId;
    EnumerableSet.UintSet internal _proposalIds;
    mapping(uint256 => Proposal) internal _proposals;

    function createProposal(
        Call[] calldata calls_
    ) external override onlyOwner returns (uint256) {
        uint256 id_ = _nextProposalId++;
        _proposalIds.add(id_);
        uint256 ready = uint256(block.timestamp) +
            _validateCallsAndGetMaxDelay(calls_);
        _proposals[id_].id = id_;
        _proposals[id_].ready = ready;
        for (uint256 i; i < calls_.length; i++) {
            _proposals[id_].calls.push(calls_[i]);
        }
        emit ProposalCreated(id_, ready, calls_);
        return id_;
    }

    function cancelProposal(uint256 id_) external onlyOwner {
        Proposal memory proposal_ = _proposals[id_];
        if (proposal_.ready == 0) revert ProposalDoesNotExist(id_);
        _deleteProposal(id_);
        emit ProposalCancelled(id_);
    }

    function setDelay(bytes4 selector_, uint256 delay_) external {
        if (msg.sender != address(this)) revert NotAuthorized();
        _delays[selector_] = delay_;
        emit DelaySet(selector_, delay_);
    }

    function executeProposal(uint256 id_) external override onlyOwner {
        Proposal memory proposal_ = _proposals[id_];
        if (proposal_.ready == 0) revert ProposalDoesNotExist(id_);
        if (proposal_.ready > block.timestamp) revert ProposalNotReady(id_);

        for (uint256 i; i < proposal_.calls.length; i++) {
            Call memory call_ = proposal_.calls[i];
            call_.target.functionCall(call_.data);
        }

        _deleteProposal(id_);
        emit ProposalExecuted(id_);
    }

    function allProposals() external view returns (Proposal[] memory p) {
        uint256[] memory proposalIds_ = _proposalIds.values();
        Proposal[] memory proposals_ = new Proposal[](proposalIds_.length);
        for (uint256 i; i < proposalIds_.length; i++) {
            proposals_[i] = _proposals[proposalIds_[i]];
        }
        return proposals_;
    }

    function readyProposals()
        external
        view
        override
        returns (Proposal[] memory)
    {
        return _filterProposals(true);
    }

    function pendingProposals()
        external
        view
        override
        returns (Proposal[] memory)
    {
        return _filterProposals(false);
    }

    function delay(bytes4 selector) external view override returns (uint256) {
        return _delays[selector];
    }

    function _deleteProposal(uint256 id_) internal {
        _proposalIds.remove(id_);
        delete _proposals[id_];
    }

    function _filterProposals(
        bool ready
    ) internal view returns (Proposal[] memory) {
        uint256[] memory proposalIds_ = _proposalIds.values();
        Proposal[] memory proposals_ = new Proposal[](proposalIds_.length);
        uint256 count_;
        for (uint256 i; i < proposalIds_.length; i++) {
            uint256 id_ = proposalIds_[i];
            Proposal memory proposal_ = _proposals[id_];
            if (ready == proposal_.ready > block.timestamp) continue;
            proposals_[count_++] = proposal_;
        }
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Truncate the array by storing `count` in the first 32 bytes memory
            mstore(proposals_, count_)
        }
        return proposals_;
    }

    function _validateCallsAndGetMaxDelay(
        Call[] calldata calls_
    ) internal view returns (uint256) {
        uint256 maxDelay_;
        for (uint256 i; i < calls_.length; i++) {
            if (calls_[i].target == address(0)) revert InvalidTarget();
            uint256 delay_ = _getDelay(calls_[i].data);
            if (delay_ > maxDelay_) maxDelay_ = delay_;
        }
        return maxDelay_;
    }

    function _getDelay(bytes calldata data_) internal view returns (uint256) {
        bytes4 selector_ = bytes4(data_[:4]);
        // Setting the delay for the setDelay function be the delay of the function it's setting
        if (selector_ == this.setDelay.selector) {
            bytes memory dataMemory_ = data_;
            // Skips the data for setDelay to get the selector fro which the delay is being set
            // solhint-disable-next-line no-inline-assembly
            assembly {
                selector_ := mload(add(dataMemory_, 36))
            }
        }

        return _delays[selector_];
    }
}
