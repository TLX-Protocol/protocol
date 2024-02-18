// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IAddressProvider} from "../interfaces/IAddressProvider.sol";

abstract contract TlxOwnable {
    error NotOwner();

    IAddressProvider private immutable _addressProvider;

    constructor(address addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
    }

    modifier onlyOwner() {
        if (_addressProvider.owner() != msg.sender) {
            revert NotOwner();
        }
        _;
    }
}
