// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IOracle {
    error RoundNotComplete();
    error StalePrice();
    error ZeroPrice();
    error RoundExpired();
    error NoOracle();

    function setUsdOracle(address token_, address oracle_) external;

    function setEthOracle(address token_, address oracle_) external;

    function setStalePriceDelay(uint256 delay_) external;

    function getUsdPrice(address token_) external view returns (uint256);

    function stalePriceDelay() external view returns (uint256);
}
