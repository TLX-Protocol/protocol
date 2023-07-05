// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract AddressProvider is IAddressProvider, Ownable, Initializable {
    address public override leveragedTokenFactory;
    address public override positionManagerFactory;
    address public override oracle;

    function initialize(
        address leveragedTokenFactory_,
        address positionManagerFactory_,
        address oracle_
    ) external override initializer onlyOwner {
        leveragedTokenFactory = leveragedTokenFactory_;
        positionManagerFactory = positionManagerFactory_;
        oracle = oracle_;
    }

    function setOracle(address oracle_) external override onlyOwner {
        oracle = oracle_;
    }
}
