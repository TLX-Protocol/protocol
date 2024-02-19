// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IAddressProvider} from "../interfaces/IAddressProvider.sol";

abstract contract TlxOwnable {
    IAddressProvider private immutable _addressProvider;

    error NotOwner();

    modifier onlyOwner() {
        if (_addressProvider.owner() != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    constructor(address addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
    }
}
