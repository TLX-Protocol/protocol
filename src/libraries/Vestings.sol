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
            account: address(770), // TODO
            amount: Config.VESTING_AMOUNT // TODO
        });

        // Max
        vestings_[1] = IVesting.VestingAmount({
            account: address(771), // TODO
            amount: 0 // TODO
        });

        // Louis
        vestings_[2] = IVesting.VestingAmount({
            account: address(772), // TODO
            amount: 0 // TODO
        });

        // Olivier
        vestings_[3] = IVesting.VestingAmount({
            account: address(773), // TODO
            amount: 0 // TODO
        });

        // Chase
        vestings_[4] = IVesting.VestingAmount({
            account: address(774), // TODO
            amount: 0 // TODO
        });

        // Daniel
        vestings_[5] = IVesting.VestingAmount({
            account: address(775), // TODO
            amount: 0 // TODO
        });

        // Paul
        vestings_[6] = IVesting.VestingAmount({
            account: address(776), // TODO
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
