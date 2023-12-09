// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IParameterProvider {
    event ParameterUpdated(bytes32 indexed key, uint256 value);

    struct Parameter {
        bytes32 key;
        uint256 value;
    }

    /**
     * @notice Updates a parameter for the given key.
     * @param key The key of the parameter to be updated.
     * @param value The value of the parameter to be updated.
     */
    function updateParameter(bytes32 key, uint256 value) external;

    /**
     * @notice Returns the parameter for a given key.
     * @param key The key of the parameter to be returned.
     * @return value The parameter  for the given key.
     */
    function parameterOf(bytes32 key) external view returns (uint256 value);

    /**
     * @notice Returns the redemption fee parameter.
     * @return redemptionFee The redemption fee parameter.
     */
    function redemptionFee() external view returns (uint256);

    /**
     * @notice Returns the streaming fee parameter.
     * @return streamingFee The streaming fee parameter.
     */
    function streamingFee() external view returns (uint256);

    /**
     * @notice Returns all parameters.
     * @return parameters All parameters.
     */
    function parameters() external view returns (Parameter[] memory parameters);
}
