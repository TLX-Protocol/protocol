// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {ITlxToken} from "./interfaces/ITlxToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract TlxToken is ITlxToken, ERC20 {
    constructor(
        address addressProvider_,
        uint256 airdropAmount_,
        uint256 bondingAmount_,
        uint256 treasuryAmount_,
        uint256 vestingAmount_
    ) ERC20("TLX DAO Token", "TLX") {
        _mint(IAddressProvider(addressProvider_).airdrop(), airdropAmount_);
        _mint(IAddressProvider(addressProvider_).bonding(), bondingAmount_);
        _mint(IAddressProvider(addressProvider_).treasury(), treasuryAmount_);
        _mint(IAddressProvider(addressProvider_).vesting(), vestingAmount_);
    }
}
