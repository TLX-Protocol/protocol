// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import {ITimelock} from "./interfaces/ITimelock.sol";

contract Timelock is ITimelock, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    mapping(bytes4 => uint256) internal _delays;
    uint256 internal _nextCallId;
    EnumerableSet.UintSet internal _callIds;
    mapping(uint256 => Call) internal _calls;

    function prepareCall(
        address target_,
        bytes calldata data_
    ) external onlyOwner {
        _prepareCall(target_, data_);
    }

    function prepareProposal(
        Proposal calldata proposal
    ) external onlyOwner returns (uint256[] memory) {
        require(
            proposal.targets.length == proposal.data.length,
            "call targets and data are not of equal length"
        );
        uint256 count = proposal.targets.length;
        uint256[] memory ids = new uint256[](count);
        uint256 currentId;
        for (uint256 i = 0; i < count; i++) {
            currentId = _prepareCall(proposal.targets[i], proposal.data[i]);
            ids[i] = currentId;
        }
        return ids;
    }

    function executeMultiple(
        uint256[] calldata ids
    ) external onlyOwner returns (bytes[] memory) {
        uint256 count = ids.length;
        bytes[] memory returnData = new bytes[](count);
        bytes memory currentReturnData;
        for (uint256 i = 0; i < count; i++) {
            currentReturnData = _executeCall(ids[i]);
            returnData[i] = currentReturnData;
        }
        return returnData;
    }

    function executeCall(
        uint256 id_
    ) external onlyOwner returns (bytes memory) {
        return _executeCall(id_);
    }

    function cancelCall(uint256 id_) external onlyOwner {
        Call memory call_ = _calls[id_];
        if (call_.target == address(0)) revert CallDoesNotExist(id_);
        _deleteCall(id_);
        emit CallCancelled(id_, call_.target, call_.data);
    }

    function setDelay(bytes4 selector_, uint256 delay_) external {
        if (msg.sender != address(this)) revert NotAuthorized();
        _delays[selector_] = delay_;
        emit DelaySet(selector_, delay_);
    }

    function allCalls() external view returns (Call[] memory) {
        uint256[] memory callIds_ = _callIds.values();
        Call[] memory calls_ = new Call[](callIds_.length);
        for (uint256 i; i < callIds_.length; i++) {
            calls_[i] = _calls[callIds_[i]];
        }
        return calls_;
    }

    function readyCalls() external view returns (Call[] memory) {
        return _filterCalls(true);
    }

    function pendingCalls() external view returns (Call[] memory) {
        return _filterCalls(false);
    }

    function delay(bytes4 selector) external view override returns (uint256) {
        return _delays[selector];
    }

    function _deleteCall(uint256 id_) internal {
        _callIds.remove(id_);
        delete _calls[id_];
    }

    function _prepareCall(
        address target_,
        bytes calldata data_
    ) internal returns (uint256) {
        if (target_ == address(0)) revert InvalidTarget();
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

        uint256 id_ = _nextCallId++;
        _callIds.add(id_);
        _calls[id_] = (
            Call({
                id: id_,
                ready: uint256(block.timestamp) + _delays[selector_],
                target: target_,
                data: data_
            })
        );
        emit CallPrepared(id_, target_, data_);
        return id_;
    }

    function _executeCall(uint256 id_) internal returns (bytes memory) {
        Call memory call_ = _calls[id_];
        if (call_.target == address(0)) revert CallDoesNotExist(id_);
        if (call_.ready > block.timestamp) revert CallNotReady(id_);
        // solhint-disable-next-line avoid-low-level-calls
        bytes memory returnData_ = call_.target.functionCall(call_.data);
        _deleteCall(id_);
        emit CallExecuted(id_, call_.target, call_.data);
        return returnData_;
    }

    function _filterCalls(bool ready) internal view returns (Call[] memory) {
        uint256[] memory callIds_ = _callIds.values();
        Call[] memory calls_ = new Call[](callIds_.length);
        uint256 count_;
        for (uint256 i; i < callIds_.length; i++) {
            uint256 id_ = callIds_[i];
            if (ready == _calls[id_].ready > block.timestamp) continue;
            calls_[count_] = _calls[id_];
            count_++;
        }
        // Truncate the array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(calls_, count_)
        }
        return calls_;
    }
}
