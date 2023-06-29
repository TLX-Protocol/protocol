// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {IOracle} from "./interfaces/IOracle.sol";

interface IChainlinkOracle {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
}

contract Oracle is IOracle, Ownable {
    using ScaledNumber for uint256;

    address internal immutable _ethUsdOracle;
    mapping(address => address) internal _usdOracles;
    mapping(address => address) internal _ethOracles;

    uint256 public override stalePriceDelay;

    constructor(address ethUsdOracle_) {
        _ethUsdOracle = ethUsdOracle_;

        stalePriceDelay = 1 days;
    }

    function setUsdOracle(
        address token_,
        address oracle_
    ) external override onlyOwner {
        _usdOracles[token_] = oracle_;
    }

    function setEthOracle(
        address token_,
        address oracle_
    ) external override onlyOwner {
        _ethOracles[token_] = oracle_;
    }

    function setStalePriceDelay(uint256 delay_) external override onlyOwner {
        stalePriceDelay = delay_;
    }

    function getUsdPrice(
        address token_
    ) external view override returns (uint256) {
        address usdOracle_ = _usdOracles[token_];
        if (usdOracle_ != address(0)) return _getChainlinkPrice(usdOracle_);
        address ethOracle_ = _ethOracles[token_];
        if (ethOracle_ == address(0)) revert NoOracle();
        uint256 ethPrice_ = _getChainlinkPrice(ethOracle_);
        uint256 ethUsdPrice_ = _getChainlinkPrice(_ethUsdOracle);
        return (ethPrice_ * ethUsdPrice_) / 1e18;
    }

    function _getChainlinkPrice(
        address oracle_
    ) internal view returns (uint256) {
        (
            uint80 roundId_,
            int256 price_,
            ,
            uint256 updatedAt_,
            uint80 answeredInRound_
        ) = IChainlinkOracle(oracle_).latestRoundData();
        if (updatedAt_ == 0) revert RoundNotComplete();
        if (block.timestamp > updatedAt_ + stalePriceDelay) revert StalePrice();
        if (price_ == 0) revert ZeroPrice();
        if (answeredInRound_ < roundId_) revert RoundExpired();
        return uint256(price_).scaleFrom(IChainlinkOracle(oracle_).decimals());
    }
}
