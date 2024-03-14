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
        UserUnstakes storage self,
        uint256 amount,
        uint256 unstakeTime
    ) internal returns (uint256) {
        uint256 id = self.nextId;
        self.withdrawals[id] = UserUnstake({
            amount: uint192(amount),
            unstakeTime: uint64(unstakeTime)
        });
        self.ids.add(id);
        self.nextId++;
        self.totalQueued += uint192(amount);
        return id;
    }

    function remove(
        UserUnstakes storage self,
        uint256 id
    ) internal returns (UserUnstake memory withdrawal) {
        if (!self.ids.remove(id)) revert Errors.DoesNotExist();
        withdrawal = self.withdrawals[id];
        self.totalQueued -= withdrawal.amount;
        delete self.withdrawals[id];
    }

    function list(
        UserUnstakes storage self
    ) internal view returns (UserUnstakeData[] memory withdrawals) {
        uint256 length = self.ids.length();
        withdrawals = new UserUnstakeData[](length);
        for (uint256 i; i < length; i++) {
            uint256 id = self.ids.at(i);
            UserUnstake memory withdrawal = self.withdrawals[id];
            withdrawals[i] = UserUnstakeData({
                id: id,
                amount: withdrawal.amount,
                unstakeTime: withdrawal.unstakeTime
            });
        }
    }
}
