// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IAddressProvider {
    event AddressUpdated(bytes32 indexed key, address value);

    function updateAddress(bytes32 key, address value) external;

    function addressOf(bytes32 key) external view returns (address);

    function leveragedTokenFactory() external view returns (address);

    function positionManagerFactory() external view returns (address);

    function oracle() external view returns (address);
}
