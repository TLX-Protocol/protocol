// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "./Errors.sol";

library Unstakes {
    using EnumerableSet for EnumerableSet.UintSet;

    struct UserUnstakeData {
        uint256 id;
        uint256 amount;
        uint256 unstakeTime;
    }

    struct UserUnstake {
        uint192 amount;
        uint64 unstakeTime;
    }

    struct UserUnstakes {
        mapping(uint256 => UserUnstake) withdrawals;
        EnumerableSet.UintSet ids;
        uint64 nextId;
        uint192 totalQueued;
    }

    function queue(
        UserUnstakes storage self_,
        uint256 amount_,
        uint256 unstakeTime_
    ) internal returns (uint256) {
        uint256 id = self_.nextId;
        self_.withdrawals[id] = UserUnstake({
            amount: uint192(amount_),
            unstakeTime: uint64(unstakeTime_)
        });
        self_.ids.add(id);
        self_.nextId++;
        self_.totalQueued += uint192(amount_);
        return id;
    }

    function remove(
        UserUnstakes storage self_,
        uint256 id_
    ) internal returns (UserUnstake memory withdrawal) {
        if (!self_.ids.remove(id_)) revert Errors.DoesNotExist();
        withdrawal = self_.withdrawals[id_];
        self_.totalQueued -= withdrawal.amount;
        delete self_.withdrawals[id_];
    }

    function list(
        UserUnstakes storage self_
    ) internal view returns (UserUnstakeData[] memory withdrawals) {
        uint256 length_ = self_.ids.length();
        withdrawals = new UserUnstakeData[](length_);
        for (uint256 i_; i_ < length_; i_++) {
            uint256 id_ = self_.ids.at(i_);
            UserUnstake memory withdrawal = self_.withdrawals[id_];
            withdrawals[i_] = UserUnstakeData({
                id: id_,
                amount: withdrawal.amount,
                unstakeTime: withdrawal.unstakeTime
            });
        }
    }
}
