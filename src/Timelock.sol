// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import {Errors} from "./libraries/Errors.sol";

import {ITimelock} from "./interfaces/ITimelock.sol";

contract Timelock is ITimelock, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(bytes4 => uint256) internal _delays;
    uint256 internal _nextProposalId;
    EnumerableSet.UintSet internal _proposalIds;
    mapping(uint256 => Proposal) internal _proposals;

    /// @inheritdoc ITimelock
    function createProposal(
        Call[] calldata calls_
    ) external override onlyOwner returns (uint256) {
        uint256 id_ = _nextProposalId++;
        _proposalIds.add(id_);
        uint256 ready_ = uint256(block.timestamp) +
            _validateCallsAndGetMaxDelay(calls_);
        _proposals[id_].id = id_;
        _proposals[id_].ready = ready_;
        for (uint256 i_; i_ < calls_.length; i_++) {
            _proposals[id_].calls.push(calls_[i_]);
        }
        emit ProposalCreated(id_, ready_, calls_);
        return id_;
    }

    /// @inheritdoc ITimelock
    function cancelProposal(uint256 id_) external onlyOwner {
        Proposal memory proposal_ = _proposals[id_];
        if (proposal_.ready == 0) revert ProposalDoesNotExist(id_);
        _deleteProposal(id_);
        emit ProposalCancelled(id_);
    }

    /// @inheritdoc ITimelock
    function setDelay(bytes4 selector_, uint256 delay_) external {
        if (msg.sender != address(this)) revert Errors.NotAuthorized();
        _delays[selector_] = delay_;
        emit DelaySet(selector_, delay_);
    }

    /// @inheritdoc ITimelock
    function executeProposal(uint256 id_) external override onlyOwner {
        Proposal memory proposal_ = _proposals[id_];
        if (proposal_.ready == 0) revert ProposalDoesNotExist(id_);
        if (proposal_.ready > block.timestamp) revert ProposalNotReady(id_);

        for (uint256 i_; i_ < proposal_.calls.length; i_++) {
            Call memory call_ = proposal_.calls[i_];
            call_.target.functionCall(call_.data);
        }

        _deleteProposal(id_);
        emit ProposalExecuted(id_);
    }

    /// @inheritdoc ITimelock
    function allProposals() external view returns (Proposal[] memory p) {
        uint256[] memory proposalIds_ = _proposalIds.values();
        Proposal[] memory proposals_ = new Proposal[](proposalIds_.length);
        for (uint256 i_; i_ < proposalIds_.length; i_++) {
            proposals_[i_] = _proposals[proposalIds_[i_]];
        }
        return proposals_;
    }

    /// @inheritdoc ITimelock
    function readyProposals()
        external
        view
        override
        returns (Proposal[] memory)
    {
        return _filterProposals(true);
    }

    /// @inheritdoc ITimelock
    function pendingProposals()
        external
        view
        override
        returns (Proposal[] memory)
    {
        return _filterProposals(false);
    }

    /// @inheritdoc ITimelock
    function delay(bytes4 selector) external view override returns (uint256) {
        return _delays[selector];
    }

    function _deleteProposal(uint256 id_) internal {
        _proposalIds.remove(id_);
        delete _proposals[id_];
    }

    function _filterProposals(
        bool ready_
    ) internal view returns (Proposal[] memory) {
        uint256[] memory proposalIds_ = _proposalIds.values();
        Proposal[] memory proposals_ = new Proposal[](proposalIds_.length);
        uint256 count_;
        for (uint256 i_; i_ < proposalIds_.length; i_++) {
            uint256 id_ = proposalIds_[i_];
            Proposal memory proposal_ = _proposals[id_];
            if (ready_ == proposal_.ready > block.timestamp) continue;
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
        for (uint256 i_; i_ < calls_.length; i_++) {
            if (calls_[i_].target == address(0)) revert InvalidTarget();
            uint256 delay_ = _getDelay(calls_[i_].data);
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
