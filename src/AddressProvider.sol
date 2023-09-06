// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import {AddressKeys} from "./libraries/AddressKeys.sol";

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract AddressProvider is IAddressProvider, Ownable, Initializable {
    mapping(bytes32 => address) internal _addresses;

    function updateAddress(
        bytes32 key_,
        address value_
    ) external override onlyOwner {
        _addresses[key_] = value_;
        emit AddressUpdated(key_, value_);
    }

    function addressOf(bytes32 key_) external view override returns (address) {
        return _addresses[key_];
    }

    function leveragedTokenFactory() external view override returns (address) {
        return _addresses[AddressKeys.LEVERAGED_TOKEN_FACTORY];
    }

    function positionManagerFactory() external view override returns (address) {
        return _addresses[AddressKeys.POSITION_MANAGER_FACTORY];
    }

    function oracle() external view override returns (address) {
        return _addresses[AddressKeys.ORACLE];
    }

    function derivativesHandler() external view override returns (address) {
        return _addresses[AddressKeys.DERIVATIVES_HANDLER];
    }
}
