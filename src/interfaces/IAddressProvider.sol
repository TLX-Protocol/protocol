// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IAddressProvider {
    event OracleUpdated(address oracle);

    function initialize(
        address leveragedTokenFactory_,
        address positionManagerFactory_,
        address oracle_
    ) external;

    function setOracle(address oracle_) external;

    function leveragedTokenFactory() external view returns (address);

    function positionManagerFactory() external view returns (address);

    function oracle() external view returns (address);
}
