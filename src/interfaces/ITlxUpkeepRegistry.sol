// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ITlxUpkeepRegistry {
    struct Upkeep {
        uint256 id;
        address registryAddress;
        address upkeepAddress;
    }

    event UpkeepAdded(
        uint256 indexed upkeepID,
        address registryAddress,
        address upkeepAddress
    );
    event UpkeepRemoved(uint256 indexed upkeepID);

    /**
     * @notice Adds a chainlink upkeep to the registry.
     * @dev Reverts if the `upkeep` is already registered.
     * @param upkeep The chainlink information for the upkeep.
     */
    function addUpkeep(Upkeep calldata upkeep) external;

    /**
     * @notice Removes the `upkeepID` as a registered upkeep.
     * @dev Reverts if the `upkeep` is not a registered.
     * @param upkeepID The chainlink ID of the upkeep to be removed.
     */
    function removeUpkeep(uint256 upkeepID) external;

    /**
     * @notice Returns if the given `upkeepID` is a registered upkeep.
     * @param upkeepID The chainlink ID of the upkeep to be checked.
     * @return isUpkeep Whether the upkeepID is a registered upkeep.
     */
    function isUpkeep(uint256 upkeepID) external view returns (bool isUpkeep);

    /**
     * @notice Returns the list of IDs of registered upkeeps.
     * @return upkeeps The list of IDs.
     */
    function allUpkeepIDs() external view returns (uint256[] memory upkeeps);

    /**
     * @notice Returns the upkeep info for a given ID.
     * @param  upkeepID The ID to get the upkeep info for.
     * @return upkeepInfo The upkeep info.
     */
    function upkeepInfoForID(
        uint256 upkeepID
    ) external view returns (Upkeep memory upkeepInfo);

    /**
     * @notice Returns the list of IDs and infos of registered upkeeps.
     * @return upkeeps The list of upkeeps.
     */
    function allUpkeepIDsAndInfo()
        external
        view
        returns (Upkeep[] memory upkeeps);
}
