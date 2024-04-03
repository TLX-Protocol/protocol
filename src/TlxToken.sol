// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import {TlxOwnable} from "./utils/TlxOwnable.sol";

import {ITlxToken} from "./interfaces/ITlxToken.sol";

import {InitialMint} from "./libraries/InitialMint.sol";

contract TlxToken is ITlxToken, ERC20, Initializable, TlxOwnable {
    using Address for address;

    constructor(
        string memory name_,
        string memory symbol_,
        address addressProvider_
    ) ERC20(name_, symbol_) TlxOwnable(addressProvider_) {}

    function mintInitialSupply(
        InitialMint.Data[] memory mintData_
    ) external initializer onlyOwner {
        for (uint256 i; i < mintData_.length; i++) {
            InitialMint.Data memory data_ = mintData_[i];
            _mint(data_.receiver, data_.amount);

            for (uint256 j_; j_ < data_.actions.length; j_++) {
                InitialMint.Action memory action_ = data_.actions[j_];
                action_.target.functionCall(action_.data);
            }
        }
    }
}
