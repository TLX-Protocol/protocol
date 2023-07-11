// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IOracle {
    /**
     * @notice Returns the price of the given token in USD (18 decimals).
     * @param token The token to get the price of.
     * @return price The price of the given token in USD (18 decimals).
     */
    function getUsdPrice(address token) external view returns (uint256 price);
}
