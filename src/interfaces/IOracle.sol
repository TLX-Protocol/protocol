// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IOracle {
    error NotLeveragedToken();

    /**
     * @notice Returns the price of the given asset in the base asset (18 decimals).
     * @param asset The asset to get the price of.
     * @return price The price of the given asset in the base asset (18 decimals).
     */
    function getPrice(
        string calldata asset
    ) external view returns (uint256 price);
}
