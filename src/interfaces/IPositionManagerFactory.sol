// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IPositionManagerFactory {
    event PositionManagerCreated(address indexed positionManager);

    error AlreadyExists();
    error NoOracle();

    function createPositionManager(
        address targetAsset_
    ) external returns (address);

    function positionManagers() external view returns (address[] memory);

    function positionManager(
        address targetAsset_
    ) external view returns (address);
}
