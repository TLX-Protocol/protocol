// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "./Errors.sol";

library Withdrawals {
    using EnumerableSet for EnumerableSet.UintSet;

    struct UserWithdrawalData {
        uint256 id;
        uint256 amount;
        uint256 unstakeTime;
    }

    struct UserWithdrawal {
        uint192 amount;
        uint64 unstakeTime;
    }

    struct UserWithdrawals {
        mapping(uint256 => UserWithdrawal) withdrawals;
        EnumerableSet.UintSet ids;
        uint64 nextId;
        uint192 totalQueued;
    }

    function queue(
        UserWithdrawals storage self,
        uint256 amount,
        uint256 unstakeTime
    ) internal returns (uint256) {
        uint256 id = self.nextId;
        self.withdrawals[id] = UserWithdrawal({
            amount: uint192(amount),
            unstakeTime: uint64(unstakeTime)
        });
        self.ids.add(id);
        self.nextId++;
        self.totalQueued += uint192(amount);
        return id;
    }

    function remove(
        UserWithdrawals storage self,
        uint256 id
    ) internal returns (UserWithdrawal memory withdrawal) {
        if (!self.ids.remove(id)) revert Errors.DoesNotExist();
        withdrawal = self.withdrawals[id];
        self.totalQueued -= withdrawal.amount;
        delete self.withdrawals[id];
    }

    function tryGet(
        UserWithdrawals storage self,
        uint256 id
    ) internal view returns (UserWithdrawal memory, bool) {
        UserWithdrawal memory withdrawal = self.withdrawals[id];
        return (withdrawal, withdrawal.amount > 0);
    }

    function get(
        UserWithdrawals storage self,
        uint256 id
    ) internal view returns (UserWithdrawal memory) {
        (UserWithdrawal memory withdrawal_, bool exists_) = tryGet(self, id);
        if (!exists_) revert Errors.DoesNotExist();
        return withdrawal_;
    }

    function list(
        UserWithdrawals storage self
    ) internal view returns (UserWithdrawalData[] memory withdrawals) {
        uint256 length = self.ids.length();
        withdrawals = new UserWithdrawalData[](length);
        for (uint256 i; i < length; i++) {
            uint256 id = self.ids.at(i);
            UserWithdrawal memory withdrawal = self.withdrawals[id];
            withdrawals[i] = UserWithdrawalData({
                id: id,
                amount: withdrawal.amount,
                unstakeTime: withdrawal.unstakeTime
            });
        }
    }
}
