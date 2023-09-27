// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IPositionManagerFactory {
    event PositionManagerCreated(address indexed positionManager);

    error NoOracle();

    /**
     * @notice Creates a new position manager for the given target asset.
     * @dev Reverts if a position manager for the given target asset already exists.
     * @param targetAsset The target asset to create a position manager for.
     * @return positionManager The address of the newly created position manager.
     */
    function createPositionManager(
        address targetAsset
    ) external returns (address positionManager);

    /**
     * @notice Returns all position managers.
     * @return positionManagers The addresses of all position managers.
     */
    function positionManagers()
        external
        view
        returns (address[] memory positionManagers);

    /**
     * @notice Returns the position manager for the given target asset.
     * @param targetAsset The target asset of the position manager.
     * @return positionManager The address of the position manager.
     */
    function positionManager(
        address targetAsset
    ) external view returns (address positionManager);

    /**
     * @notice Returns whether the given address is a position manager.
     * @param positionManager The address to check.
     * @return isPositionManager Whether the given address is a position manager.
     */
    function isPositionManager(
        address positionManager
    ) external view returns (bool isPositionManager);
}
