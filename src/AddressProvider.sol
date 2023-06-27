// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract AddressProvider is IAddressProvider {
    address public immutable override leveragedTokenFactory;

    constructor(address leveragedTokenFactory_) {
        leveragedTokenFactory = leveragedTokenFactory_;
    }
}
