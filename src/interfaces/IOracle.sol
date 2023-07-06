// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IOracle {
    function getUsdPrice(address token_) external view returns (uint256);
}
