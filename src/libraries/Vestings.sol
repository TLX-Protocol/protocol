// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IVesting} from "../interfaces/IVesting.sol";
import {Config} from "../libraries/Config.sol";

library Vestings {
    error InvalidAmounts();

    function vestings()
        internal
        pure
        returns (IVesting.VestingAmount[] memory)
    {
        IVesting.VestingAmount[]
            memory vestings_ = new IVesting.VestingAmount[](7);

        // Sam
        vestings_[0] = IVesting.VestingAmount({
            account: address(1), // TODO
            amount: Config.VESTING_AMOUNT // TODO
        });

        // Max
        vestings_[1] = IVesting.VestingAmount({
            account: address(2), // TODO
            amount: 0 // TODO
        });

        // Louis
        vestings_[2] = IVesting.VestingAmount({
            account: address(3), // TODO
            amount: 0 // TODO
        });

        // Olivier
        vestings_[3] = IVesting.VestingAmount({
            account: address(4), // TODO
            amount: 0 // TODO
        });

        // Chase
        vestings_[4] = IVesting.VestingAmount({
            account: address(5), // TODO
            amount: 0 // TODO
        });

        // Daniel
        vestings_[5] = IVesting.VestingAmount({
            account: address(6), // TODO
            amount: 0 // TODO
        });

        // Paul
        vestings_[6] = IVesting.VestingAmount({
            account: address(7), // TODO
            amount: 0 // TODO
        });

        // TODO: Investors/Advisors

        // Validating amounts
        validateAmounts(vestings_);

        return vestings_;
    }

    function validateAmounts(
        IVesting.VestingAmount[] memory vestings_
    ) internal pure {
        uint256 totalAmount_;
        for (uint256 i; i < vestings_.length; i++) {
            totalAmount_ += vestings_[i].amount;
        }

        if (totalAmount_ != Config.VESTING_AMOUNT) revert InvalidAmounts();
    }
}
