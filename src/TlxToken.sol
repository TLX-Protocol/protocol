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

        for (uint256 i = 0; i < mintData_.length; i++) {
            InitialMint.Data memory data = mintData_[i];
            _mint(data.receiver, data.amount);

            for (uint256 j; j < data.actions.length; j++) {
                InitialMint.Action memory action = data.actions[j];
                action.target.functionCall(
                    action.data,
                    "TlxToken: action call failed"
                );
            }
        }
    }
}
