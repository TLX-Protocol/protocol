// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {IChainlinkOracle} from "./interfaces/IChainlinkOracle.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";
import {ILeveragedTokenFactory} from "./interfaces/ILeveragedTokenFactory.sol";
import {IPositionManager} from "./interfaces/IPositionManager.sol";
import {IPositionManagerFactory} from "./interfaces/IPositionManagerFactory.sol";

interface IChainlink {
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

contract ChainlinkOracle is IChainlinkOracle, Ownable {
    using ScaledNumber for uint256;

    address internal immutable _ethUsdOracle;
    address internal immutable _addressProvider;

    mapping(address => address) internal _usdOracles;
    mapping(address => address) internal _ethOracles;

    uint256 public override stalePriceDelay = 1 days;

    constructor(address addressProvider_, address ethUsdOracle_) {
        _ethUsdOracle = ethUsdOracle_;
        _addressProvider = addressProvider_;
    }

    function setUsdOracle(
        address token_,
        address oracle_
    ) external override onlyOwner {
        _usdOracles[token_] = oracle_;
        emit UsdOracleUpdated(token_, oracle_);
    }

    function setEthOracle(
        address token_,
        address oracle_
    ) external override onlyOwner {
        _ethOracles[token_] = oracle_;
        emit EthOracleUpdated(token_, oracle_);
    }

    function setStalePriceDelay(uint256 delay_) external override onlyOwner {
        stalePriceDelay = delay_;
        emit StalePriceDelayUpdated(delay_);
    }

    function getUsdPrice(
        address token_
    ) public view override returns (uint256) {
        if (_isLeveragedToken(token_)) return _priceLeveragedToken(token_);
        address usdOracle_ = _usdOracles[token_];
        if (usdOracle_ != address(0)) return _getChainlinkPrice(usdOracle_);
        address ethOracle_ = _ethOracles[token_];
        if (ethOracle_ == address(0)) revert NoOracle();
        uint256 ethPrice_ = _getChainlinkPrice(ethOracle_);
        uint256 ethUsdPrice_ = _getChainlinkPrice(_ethUsdOracle);
        return ethPrice_.mul(ethUsdPrice_);
    }

    function _priceLeveragedToken(
        address token_
    ) internal view returns (uint256) {
        address baseAsset_ = ILeveragedToken(token_).baseAsset();
        return getUsdPrice(baseAsset_).mul(_exchangeRate(token_));
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
        ) = IChainlink(oracle_).latestRoundData();
        if (updatedAt_ == 0) revert RoundNotComplete();
        if (block.timestamp > updatedAt_ + stalePriceDelay) revert StalePrice();
        if (price_ == 0) revert ZeroPrice();
        if (answeredInRound_ < roundId_) revert RoundExpired();
        return uint256(price_).scaleFrom(IChainlink(oracle_).decimals());
    }

    function _isLeveragedToken(address token_) internal view returns (bool) {
        return
            ILeveragedTokenFactory(
                IAddressProvider(_addressProvider).leveragedTokenFactory()
            ).isLeveragedToken(token_);
    }

    function _exchangeRate(address token_) internal view returns (uint256) {
        return
            IPositionManager(
                IPositionManagerFactory(
                    IAddressProvider(_addressProvider).positionManagerFactory()
                ).positionManager(ILeveragedToken(token_).targetAsset())
            ).exchangeRate(token_);
    }
}
