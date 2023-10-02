// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IDerivativesHandler {
    struct Position {
        uint256 createdAt;
        address baseToken;
        string targetToken;
        uint256 baseAmount;
        uint256 leverage;
        bool isLong;
        bool hasProfit;
        uint256 delta;
    }

    error NoPositionExists();
    error PositionAlreadyExists();

    /**
     * @notice Creates a new position.
     * @param baseToken The token to be used as collateral.
     * @param targetToken The token to be traded.
     * @param baseAmount The amount of baseToken to be used as collateral.
     * @param leverage The amount of leverage to be used.
     * @param isLong Whether the position is long or short.
     */
    function createPosition(
        address baseToken,
        string calldata targetToken,
        uint256 baseAmount,
        uint256 leverage,
        bool isLong
    ) external;

    /**
     * @notice Closes the position of the sender.
     * @return baseAmountReceived The amount of baseToken received.
     */
    function closePosition() external returns (uint256 baseAmountReceived);

    /**
     * @notice Returns the position of the sender.
     * @return position The position of the sender.
     */
    function position() external view returns (Position memory position);

    /**
     * @notice Returns if the sender has a position.
     * @return hasPosition Whether the sender has a position.
     */
    function hasPosition() external view returns (bool hasPosition);

    /**
     * @notice Returns the address of contract that the sender needs to approve spending for their base tokens.
     * @return approveAddress The address of the contract that the sender needs to approve spending for their base tokens.
     */
    function approveAddress() external view returns (address approveAddress);
}
