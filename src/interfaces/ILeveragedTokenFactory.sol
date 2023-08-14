// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ILeveragedTokenFactory {
    event NewLeveragedToken(address indexed token);

    error TokenExists();
    error ZeroAddress();
    error ZeroLeverage();
    error MaxLeverage();
    error NoPositionManager();

    /**
     * @notice Creates a new Long and Short Leveraged Token for the given target asset and leverage.
     * @dev Reverts if a Leveraged Token for the given target asset and leverage already exists.
     * @param targetAsset The target asset of the Leveraged Token.
     * @param targetLeverage The target leverage of the Leveraged Token (2 decimals).
     * @return longToken The address of the Long Leveraged Token.
     * @return shortToken The address of the Short Leveraged Token.
     */
    function createLeveragedTokens(
        address targetAsset,
        uint256 targetLeverage
    ) external returns (address longToken, address shortToken);

    /**
     * @notice Returns all Leveraged Tokens.
     * @return tokens The addresses of all Leveraged Tokens.
     */
    function allTokens() external view returns (address[] memory tokens);

    /**
     * @notice Returns all Long Leveraged Tokens.
     * @return tokens The addresses of all Long Leveraged Tokens.
     */
    function longTokens() external view returns (address[] memory tokens);

    /**
     * @notice Returns all Short Leveraged Tokens.
     * @return tokens The addresses of all Short Leveraged Tokens.
     */
    function shortTokens() external view returns (address[] memory tokens);

    /**
     * @notice Returns all Leveraged Tokens for the given target asset.
     * @param targetAsset The target asset of the Leveraged Tokens.
     * @return tokens The addresses of all Leveraged Tokens for the given target asset.
     */
    function allTokens(
        address targetAsset
    ) external view returns (address[] memory tokens);

    /**
     * @notice Returns all Long Leveraged Tokens for the given target asset.
     * @param targetAsset The target asset of the Long Leveraged Tokens.
     * @return tokens The addresses of all Long Leveraged Tokens for the given target asset.
     */
    function longTokens(
        address targetAsset
    ) external view returns (address[] memory tokens);

    /**
     * @notice Returns all Short Leveraged Tokens for the given target asset.
     * @param targetAsset The target asset of the Short Leveraged Tokens.
     * @return tokens The addresses of all Short Leveraged Tokens for the given target asset.
     */
    function shortTokens(
        address targetAsset
    ) external view returns (address[] memory tokens);

    /**
     * @notice Returns the Leveraged Token for the given target asset and leverage.
     * @param targetAsset The target asset of the Leveraged Token.
     * @param targetLeverage The target leverage of the Leveraged Token (2 decimals).
     * @param isLong If the Leveraged Token is long or short.
     * @return token The address of the Leveraged Token.
     */
    function token(
        address targetAsset,
        uint256 targetLeverage,
        bool isLong
    ) external view returns (address token);

    /**
     * @notice Returns if the Leveraged Token for the given target asset and leverage exists.
     * @param targetAsset The target asset of the Leveraged Token.
     * @param targetLeverage The target leverage of the Leveraged Token (2 decimals).
     * @param isLong If the Leveraged Token is long or short.
     * @return exists If the Leveraged Token exists.
     */
    function tokenExists(
        address targetAsset,
        uint256 targetLeverage,
        bool isLong
    ) external view returns (bool exists);

    /**
     * @notice Returns if the given Leveraged Token exists.
     * @param leveragedToken The address of the Leveraged Token.
     * @return exists If the Leveraged Token exists.
     */
    function tokenExists(
        address leveragedToken
    ) external view returns (bool exists);

    /**
     * @notice Returns the Leveraged Tokens inverse pair (e.g. ETH3L -> ETH3S).
     * @param token The address of the Leveraged Token.
     * @return pair The address of the Leveraged Tokens inverse pair.
     */
    function pair(address token) external view returns (address pair);
}
