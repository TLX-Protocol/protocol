// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IAddressProvider {
    function leveragedTokenFactory() external view returns (address);

    function oracle() external view returns (address);
}
