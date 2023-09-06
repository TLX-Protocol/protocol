// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ITimelock} from "./interfaces/ITimelock.sol";

contract Timelock is ITimelock, Ownable {
    mapping(bytes4 => uint64) internal _delays;
    uint64 internal _nextCallId;
    uint64[] internal _callIds;
    mapping(uint64 => Call) internal _calls;

    function prepareCall(
        address target_,
        bytes calldata data_
    ) external onlyOwner {
        if (target_ == address(0)) revert InvalidTarget();
        bytes4 selector_ = bytes4(data_[:4]);

        // Setting the delay for the setDelay function be the delay of the function it's setting
        if (selector_ == this.setDelay.selector) {
            bytes memory dataMemory_ = data_;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                selector_ := mload(add(dataMemory_, 68))
            }
        }

        uint64 id_ = _nextCallId++;
        _callIds.push(id_);
        _calls[id_] = (
            Call({
                id: id_,
                ready: uint64(block.timestamp) + _delays[selector_],
                target: target_,
                data: data_
            })
        );
        emit CallPrepared(id_, target_, data_);
    }

    function executeCall(uint64 id_) external onlyOwner {
        Call memory call_ = _calls[id_];
        if (call_.target == address(0)) revert CallDoesNotExist(id_);
        if (call_.ready > block.timestamp) revert CallNotReady(id_);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success_, bytes memory returnData_) = call_.target.call(
            call_.data
        );
        if (!success_) revert CallFailed(id_, returnData_);
        _deleteCall(id_);
        emit CallExecuted(id_, call_.target, call_.data);
    }

    function cancelCall(uint64 id_) external onlyOwner {
        Call memory call_ = _calls[id_];
        if (call_.target == address(0)) revert CallDoesNotExist(id_);
        _deleteCall(id_);
        emit CallCancelled(id_, call_.target, call_.data);
    }

    function setDelay(bytes4 selector_, uint64 delay_) external {
        if (msg.sender != address(this)) revert NotAuthorized();
        _delays[selector_] = delay_;
        emit DelaySet(selector_, delay_);
    }

    function allCalls() external view returns (Call[] memory) {
        uint64[] memory callIds_ = _callIds;
        Call[] memory calls_ = new Call[](callIds_.length);
        for (uint256 i; i < callIds_.length; i++) {
            calls_[i] = _calls[callIds_[i]];
        }
        return calls_;
    }

    function pendingCalls() external view returns (Call[] memory) {
        uint64[] memory callIds_ = _callIds;
        Call[] memory calls_ = new Call[](callIds_.length);
        uint256 count_;
        for (uint256 i; i < callIds_.length; i++) {
            uint64 id_ = callIds_[i];
            if (_calls[id_].ready <= block.timestamp) continue;
            calls_[count_] = _calls[id_];
            count_++;
        }
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(calls_, count_)
        }
        return calls_;
    }

    function readyCalls() external view returns (Call[] memory) {
        uint64[] memory callIds_ = _callIds;
        Call[] memory calls_ = new Call[](callIds_.length);
        uint256 count_;
        for (uint256 i; i < callIds_.length; i++) {
            uint64 id_ = callIds_[i];
            if (_calls[id_].ready > block.timestamp) continue;
            calls_[count_] = _calls[id_];
            count_++;
        }
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(calls_, count_)
        }
        return calls_;
    }

    function delay(bytes4 selector) external view override returns (uint64) {
        return _delays[selector];
    }

    function _deleteCall(uint64 id_) internal {
        uint64[] memory callids_ = _callIds;
        uint256 index_;
        for (uint256 i; i < callids_.length; i++) {
            if (callids_[i] == id_) {
                index_ = i;
                break;
            }
        }
        _callIds[index_] = callids_[index_];
        _callIds.pop();
        delete _calls[id_];
    }
}
