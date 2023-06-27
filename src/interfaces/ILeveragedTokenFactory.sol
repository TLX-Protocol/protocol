// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ILeveragedTokenFactory {
    event NewLeveragedToken(address indexed token);

    error TokenExists();
    error ZeroAddress();
    error ZeroLeverage();
    error MaxLeverage();

    // Creates a new Long and Short Leveraged Token for the given target asset and leverage
    function createLeveragedTokens(
        address targetAsset,
        uint256 targetLeverage
    ) external returns (address longToken, address shortToken);

    // Returns all Leveraged Tokens
    function allTokens() external view returns (address[] memory);

    // Returns all Long Leveraged Tokens
    function longTokens() external view returns (address[] memory);

    // Returns all Short Leveraged Tokens
    function shortTokens() external view returns (address[] memory);

    // Returns all Leveraged Tokens for the given target asset
    function allTokens(
        address targetAsset
    ) external view returns (address[] memory);

    // Returns all Long Leveraged Tokens for the given target asset
    function longTokens(
        address targetAsset
    ) external view returns (address[] memory);

    // Returns all Short Leveraged Tokens for the given target asset
    function shortTokens(
        address targetAsset
    ) external view returns (address[] memory);

    // Returns the Leveraged Token for the given target asset and leverage
    function getToken(
        address targetAsset,
        uint256 targetLeverage,
        bool isLong
    ) external view returns (address);

    // Returns true if the Leveraged Token for the given target asset and leverage exists
    function tokenExists(
        address targetAsset,
        uint256 targetLeverage,
        bool isLong
    ) external view returns (bool);

    // Returns the Leveraged Tokens inverse pair (e.g. ETH3L -> ETH3S)
    function pair(address token) external view returns (address);
}
