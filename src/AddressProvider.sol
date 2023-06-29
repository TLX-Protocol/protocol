// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract AddressProvider is IAddressProvider, Ownable {
    address public immutable override leveragedTokenFactory;
    address public override oracle;

    constructor(address leveragedTokenFactory_, address oracle_) {
        leveragedTokenFactory = leveragedTokenFactory_;
        oracle = oracle_;
    }

    function setOracle(address oracle_) external onlyOwner {
        oracle = oracle_;
    }
}
