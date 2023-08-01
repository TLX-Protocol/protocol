// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

// TODO Add documentation here

interface IDerivativesHandler {
    struct Position {
        uint256 createdAt;
        address baseToken;
        address targetToken;
        uint256 baseAmount;
        uint256 leverage;
        bool isLong;
        bool hasProfit;
        uint256 delta;
    }

    error NoPositionExists();
    error PositionAlreadyExists();

    function createPosition(
        address baseToken,
        address targetToken,
        uint256 baseAmount,
        uint256 leverage,
        bool isLong
    ) external;

    function closePosition() external returns (uint256);

    function position() external view returns (Position memory);

    function hasPosition() external view returns (bool);

    function approveAddress() external view returns (address);
}
