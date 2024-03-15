// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IParameterProvider {
    struct Parameter {
        bytes32 key;
        uint256 value;
    }

    event ParameterUpdated(bytes32 indexed key, uint256 value);
    event RebalanceThresholdUpdated(address leveragedToken, uint256 value);

    error InvalidRebalanceThreshold();
    error NonExistentParameter(bytes32 key);

    /**
     * @notice Updates a parameter for the given key.
     * @param key The key of the parameter to be updated.
     * @param value The value of the parameter to be updated.
     */
    function updateParameter(bytes32 key, uint256 value) external;

    /**
     * @notice Updates the rebalance threshold for the `leveragedToken`.
     * @param leveragedToken The address of the leveraged token.
     * @param value The new rebalance threshold.
     */
    function updateRebalanceThreshold(
        address leveragedToken,
        uint256 value
    ) external;

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
     * @notice Returns the rebalance fee charged for rebalances in baseAsset.
     * @return rebalanceFee The rebalance fee.
     */
    function rebalanceFee() external view returns (uint256 rebalanceFee);

    /**
     * @notice Returns the percent buffer applied on the `maxBaseAssetAmount`.
     * @return maxBaseAssetAmountBuffer The percent buffer applied on the `maxBaseAssetAmount`.
     */
    function maxBaseAssetAmountBuffer()
        external
        view
        returns (uint256 maxBaseAssetAmountBuffer);

    /**
     * @notice Returns all parameters.
     * @return parameters All parameters.
     */
    function parameters() external view returns (Parameter[] memory parameters);

    /**
     * @notice Returns the rebalance threshold for the `leveragedToken`.
     * @param leveragedToken The address of the leveraged token.
     * @return rebalanceThreshold The rebalance threshold of the `leveragedToken`.
     */
    function rebalanceThreshold(
        address leveragedToken
    ) external view returns (uint256 rebalanceThreshold);
}
