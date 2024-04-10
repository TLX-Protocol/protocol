// SPDX-License-Identifier: GPL-3.0
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
            memory vestings_ = new IVesting.VestingAmount[](24);

        vestings_[0] = IVesting.VestingAmount({
            account: 0x3F712f446514ee0a8428B2Cc36fA271a6Dbd105C,
            amount: 833333333333333000000000
        });
        vestings_[1] = IVesting.VestingAmount({
            account: 0xb3b76046b0306E1a054bC90723A444f6fddE70C8,
            amount: 583333333333333000000000
        });
        vestings_[2] = IVesting.VestingAmount({
            account: 0xA71b4501006944B533F0442dae9aD35b7ee3C28a,
            amount: 416666666666667000000000
        });
        vestings_[3] = IVesting.VestingAmount({
            account: 0xa7393D2F073EaDD425B254A60e72c464E8fA4C20,
            amount: 250000000000000000000000
        });
        vestings_[4] = IVesting.VestingAmount({
            account: 0xD0c417aAB37c6b3ACf93dA6036bFE29963C5B3D9,
            amount: 41666666666666700000000
        });
        vestings_[5] = IVesting.VestingAmount({
            account: 0xCA2A58F421c027e98d41BCB8C4Ae019f610dd000,
            amount: 3208333333333330000000000
        });
        vestings_[6] = IVesting.VestingAmount({
            account: 0x0DC874Fb5260Bd8749e6e98fd95d161b7605774D,
            amount: 625000000000000000000000
        });
        vestings_[7] = IVesting.VestingAmount({
            account: 0xb747f20b7B729d385a844ed200e8Ce914cEFc9d8,
            amount: 20833333333333300000000
        });
        vestings_[8] = IVesting.VestingAmount({
            account: 0x189EDF27c4f4B69338FC464faea5B7977B24Dcba,
            amount: 1000000000000000000000000
        });
        vestings_[9] = IVesting.VestingAmount({
            account: 0x6ab615CF8deCFc488186E54066Fc10589C9293A3,
            amount: 1000000000000000000000000
        });
        vestings_[10] = IVesting.VestingAmount({
            account: 0x1852848a4807a6A3dD19C57e54ffAA415E7E60FF,
            amount: 4000000000000000000000000
        });
        vestings_[11] = IVesting.VestingAmount({
            account: 0x3C27e008E51B2CaBBb61fCb459914F99E40B122E,
            amount: 4000000000000000000000000
        });
        vestings_[12] = IVesting.VestingAmount({
            account: 0xb7e90Ec7FB439770D947d3298f9F90e0C4953DDA,
            amount: 3600000000000000000000000
        });
        vestings_[13] = IVesting.VestingAmount({
            account: 0x18178459f4F70B8E7Af8CEB1045Ab129D8913EEB,
            amount: 3600000000000000000000000
        });
        vestings_[14] = IVesting.VestingAmount({
            account: 0xc3E6Ef5c7DEF5c7E461EdB020a2f4D8e57465de5,
            amount: 2600000000000000000000000
        });
        vestings_[15] = IVesting.VestingAmount({
            account: 0x488a22cD5423247Bc7DD24A49362ED01682EE3FA,
            amount: 1200000000000000000000000
        });
        vestings_[16] = IVesting.VestingAmount({
            account: 0xb75399325075F285Af6A4999Fb590d553fDE93e7,
            amount: 1000000000000000000000000
        });
        vestings_[17] = IVesting.VestingAmount({
            account: 0xaCA2D12334424a94C7431Eec150249391BE6DD58,
            amount: 100000000000000000000000
        });
        vestings_[18] = IVesting.VestingAmount({
            account: 0x6Cd68E8f04490Cd1A5A21cc97CC8BC15b47Dc9eb,
            amount: 100000000000000000000000
        });
        vestings_[19] = IVesting.VestingAmount({
            account: 0xb1bfC45670a375FD94Faf50A78Cda56a4869f386,
            amount: 100000000000000000000000
        });
        vestings_[20] = IVesting.VestingAmount({
            account: 0x7fBC3fF026e49c6513BA2Ab3085c11e2CD08B808,
            amount: 100000000000000000000000
        });
        vestings_[21] = IVesting.VestingAmount({
            account: 0x55649A76422243dD6853417ce79C5148B2381D19,
            amount: 100000000000000000000000
        });
        vestings_[22] = IVesting.VestingAmount({
            account: 0x9B59228F2ae19f9C7B50e4d4755F1C85cad78C90,
            amount: 6187500000033337000000000
        });
        vestings_[23] = IVesting.VestingAmount({
            account: 0x6E28337E25717553E7f7F3e89Ad19F6cd01f3b2c,
            amount: 3000000000000000000000000
        });

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
