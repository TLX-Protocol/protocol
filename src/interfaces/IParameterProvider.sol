// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IParameterProvider {
    event ParameterUpdated(bytes32 indexed key, uint256 value);

    /**
     * @notice Updates a parameter for the given key.
     * @param key The key of the parameter to be updated.
     * @param value The value of the parameter to be updated.
     */
    function updateParameter(bytes32 key, uint256 value) external;

    /**
     * @notice Returns the parameter for a kiven key.
     * @param key The key of the parameter to be returned.
     * @return value The parameter  for the given key.
     */
    function parameterOf(bytes32 key) external view returns (uint256 value);

    /**
     * @notice Returns the rebalance threshold parameter.
     * @return rebalanceThreshold The rebalance threshold parameter.
     */
    function rebalanceThreshold() external view returns (uint256);
}
