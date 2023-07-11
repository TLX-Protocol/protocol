// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ITimelock} from "./interfaces/ITimelock.sol";

contract Timelock is ITimelock, Ownable {
    mapping(bytes4 => uint64) internal _delays;
    Call[] internal _calls;

    function prepareCall(
        address target_,
        bytes calldata data_
    ) external onlyOwner {
        bytes4 selector_ = bytes4(data_[:4]);

        // Setting the delay for the setDelay function be the delay of the function it's setting
        if (selector_ == this.setDelay.selector) {
            bytes memory dataMemory_ = data_;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                selector_ := mload(add(dataMemory_, 68))
            }
        }

        _calls.push(
            Call({
                id: uint64(_calls.length),
                ready: uint64(block.timestamp) + _delays[selector_],
                executed: 0,
                cancelled: 0,
                target: target_,
                data: data_
            })
        );
    }

    function executeCall(uint64 id_) external onlyOwner {
        Call memory call_ = _calls[id_];
        if (call_.ready > block.timestamp) revert CallNotReady(id_);
        if (call_.executed != 0) revert CallAlreadyExecuted(id_);
        if (call_.cancelled != 0) revert CallAlreadyCancelled(id_);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success_, bytes memory returnData_) = call_.target.call(
            call_.data
        );
        if (!success_) revert CallFailed(id_, returnData_);
        _calls[id_].executed = uint64(block.timestamp);
    }

    function cancelCall(uint64 id_) external onlyOwner {
        Call memory call_ = _calls[id_];
        if (call_.cancelled != 0) revert CallAlreadyCancelled(id_);
        if (call_.executed != 0) revert CallAlreadyExecuted(id_);
        _calls[id_].cancelled = uint64(block.timestamp);
    }

    function setDelay(bytes4 selector_, uint64 delay_) external {
        if (msg.sender != address(this)) revert NotAuthorized();
        _delays[selector_] = delay_;
    }

    function allCalls() external view returns (Call[] memory) {
        return _calls;
    }

    function pendingCalls() external view returns (Call[] memory) {
        Call[] memory calls_ = new Call[](_calls.length);
        uint256 count_;
        for (uint256 i; i < _calls.length; i++) {
            if (_calls[i].ready > block.timestamp) continue;
            if (_calls[i].executed != 0) continue;
            if (_calls[i].cancelled != 0) continue;
            calls_[count_] = _calls[i];
            count_++;
        }
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(calls_, count_)
        }
        return calls_;
    }

    function readyCalls() external view returns (Call[] memory) {
        Call[] memory calls_ = new Call[](_calls.length);
        uint256 count_;
        for (uint256 i; i < _calls.length; i++) {
            if (_calls[i].ready < block.timestamp) continue;
            if (_calls[i].executed != 0) continue;
            if (_calls[i].cancelled != 0) continue;
            calls_[count_] = _calls[i];
            count_++;
        }
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(calls_, count_)
        }
        return calls_;
    }

    function executedCalls() external view returns (Call[] memory) {
        Call[] memory calls_ = new Call[](_calls.length);
        uint256 count_;
        for (uint256 i; i < _calls.length; i++) {
            if (_calls[i].executed == 0) continue;
            calls_[count_] = _calls[i];
            count_++;
        }
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(calls_, count_)
        }
        return calls_;
    }

    function cancelledCalls() external view returns (Call[] memory) {
        Call[] memory calls_ = new Call[](_calls.length);
        uint256 count_;
        for (uint256 i; i < _calls.length; i++) {
            if (_calls[i].cancelled == 0) continue;
            calls_[count_] = _calls[i];
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
}
