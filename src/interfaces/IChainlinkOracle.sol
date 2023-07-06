// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IOracle} from "./IOracle.sol";

interface IChainlinkOracle is IOracle {
    event UsdOracleUpdated(address indexed token, address oracle);
    event EthOracleUpdated(address indexed token, address oracle);
    event StalePriceDelayUpdated(uint256 delay);

    error RoundNotComplete();
    error StalePrice();
    error ZeroPrice();
    error RoundExpired();
    error NoOracle();

    function setUsdOracle(address token_, address oracle_) external;

    function setEthOracle(address token_, address oracle_) external;

    function setStalePriceDelay(uint256 delay_) external;

    function stalePriceDelay() external view returns (uint256);
}
