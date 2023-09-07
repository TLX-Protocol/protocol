// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {ITlxToken} from "./interfaces/ITlxToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract TlxToken is ITlxToken, ERC20 {
    address internal immutable _addressProvider;

    modifier onlyAuthorized() {
        if (
            msg.sender != IAddressProvider(_addressProvider).airdrop() &&
            msg.sender != IAddressProvider(_addressProvider).bonding() &&
            msg.sender !=
            IAddressProvider(_addressProvider).treasuryVesting() &&
            msg.sender != IAddressProvider(_addressProvider).vesting()
        ) revert NotAuthorized();
        _;
    }

    constructor(address addressProvider_) ERC20("TLX Token", "TLX") {
        _addressProvider = addressProvider_;
    }

    function mint(
        address to_,
        uint256 amount_
    ) external override onlyAuthorized {
        _mint(to_, amount_);
    }
}
