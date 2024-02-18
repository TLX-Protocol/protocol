// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import {IOwnable} from "./interfaces/libraries/IOwnable.sol";
import {ITlxToken} from "./interfaces/ITlxToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

import {Errors} from "./libraries/Errors.sol";
import {InitialMint} from "./libraries/InitialMint.sol";

contract TlxToken is ITlxToken, ERC20, Initializable {
    using Address for address;

    address public immutable owner;

    constructor(
        string memory name_,
        string memory symbol_,
        address addressProvider_
    ) ERC20(name_, symbol_) {
        owner = IOwnable(addressProvider_).owner();
    }

    function mintInitialSupply(
        InitialMint.Data[] memory mintData_
    ) external initializer {
        if (msg.sender != owner) revert Errors.NotAuthorized();

        for (uint256 i_; i_ < mintData_.length; i_++) {
            InitialMint.Data memory data_ = mintData_[i_];
            _mint(data_.receiver, data_.amount);

            for (uint256 j_; j_ < data_.actions.length; j_++) {
                InitialMint.Action memory action_ = data_.actions[j_];
                action_.target.functionCall(
                    action_.data,
                    "TlxToken: action call failed"
                );
            }
        }
    }
}
