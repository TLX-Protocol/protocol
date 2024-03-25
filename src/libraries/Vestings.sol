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
            memory vestings_ = new IVesting.VestingAmount[](9);

        // Team (should total to 20% of total supply)

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

        // Treasury (DAO)
        vestings_[7] = IVesting.VestingAmount({
            account: Config.DAO_TREASURY,
            amount: 0 // TODO (should be 3% of total supply)
        });

        // Company Reserves
        vestings_[7] = IVesting.VestingAmount({
            account: Config.GOVERNANCE_MULTISIG,
            amount: 0 // TODO (should be 7% of total supply)
        });

        // TODO: Investors/Advisors (should total to 8% of total supply)

        // Validating amounts
        validateAmounts(vestings_);

        return vestings_;
    }

    function validateAmounts(
        IVesting.VestingAmount[] memory vestings_
    ) internal pure {
        uint256 totalAmount_;
        for (uint256 i_; i_ < vestings_.length; i_++) {
            totalAmount_ += vestings_[i_].amount;
        }

        if (totalAmount_ != Config.VESTING_AMOUNT) revert InvalidAmounts();
    }
}
