const fs = require("fs");
const path = require("path");
const { getAddress } = require("ethers");

const rootDir = path.dirname(__dirname);
const vestingsFile = path.join(rootDir, "data", "vestings.json");
const vestings = Object.entries(
  JSON.parse(fs.readFileSync(vestingsFile, "utf8"))
);

const vestingsSolidity = `// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IVesting} from "../interfaces/IVesting.sol";
import {Config} from "../libraries/Config.sol";

library Vestings {
    error InvalidAmounts(uint256 expected, uint256 actual);

    function vestings()
        internal
        pure
        returns (IVesting.VestingAmount[] memory)
    {
        IVesting.VestingAmount[]
            memory vestings_ = new IVesting.VestingAmount[](${vestings.length});
${vestings
  .map(
    ([addr, amount], i) => `
        vestings_[${i}] = IVesting.VestingAmount({
            account: ${getAddress(addr)},
            amount: ${amount}
        });`
  )
  .join("")}

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

        if (totalAmount_ != Config.VESTING_AMOUNT)
            revert InvalidAmounts(totalAmount_, Config.VESTING_AMOUNT);
    }
}
`;

fs.writeFileSync(
  path.join(rootDir, "src", "libraries", "Vestings.sol"),
  vestingsSolidity,
  "utf-8"
);
