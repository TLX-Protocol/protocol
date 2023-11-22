// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {IOracle} from "./interfaces/IOracle.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";

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

contract Oracle is IOracle, Ownable {
    using ScaledNumber for uint256;

    address internal immutable _ethUsdOracle;
    IAddressProvider internal immutable _addressProvider;

    mapping(string => address) internal _usdOracles;
    mapping(string => address) internal _ethOracles;

    uint256 public stalePriceDelay = 1 days;

    event UsdOracleUpdated(string indexed asset, address oracle);
    event EthOracleUpdated(string indexed asset, address oracle);
    event StalePriceDelayUpdated(uint256 delay);

    error RoundNotComplete();
    error StalePrice();
    error ZeroPrice();
    error RoundExpired();
    error NoOracle();

    constructor(address addressProvider_, address ethUsdOracle_) {
        _ethUsdOracle = ethUsdOracle_;
        _addressProvider = IAddressProvider(addressProvider_);
    }

    function setUsdOracle(
        string calldata asset_,
        address oracle_
    ) external onlyOwner {
        _usdOracles[asset_] = oracle_;
        emit UsdOracleUpdated(asset_, oracle_);
    }

    function setEthOracle(
        string calldata asset_,
        address oracle_
    ) external onlyOwner {
        _ethOracles[asset_] = oracle_;
        emit EthOracleUpdated(asset_, oracle_);
    }

    function setStalePriceDelay(uint256 delay_) external onlyOwner {
        stalePriceDelay = delay_;
        emit StalePriceDelayUpdated(delay_);
    }

    function getPrice(
        string calldata asset_
    ) public view override returns (uint256) {
        uint256 usdPrice_ = _getUsdPrice(asset_);
        uint256 baseAssetPrice_ = _getUsdPrice(
            _addressProvider.baseAsset().symbol()
        );
        return usdPrice_.mul(1e18).div(baseAssetPrice_);
    }

    function _getUsdPrice(
        string memory asset_
    ) internal view returns (uint256) {
        address usdOracle_ = _usdOracles[asset_];
        if (usdOracle_ != address(0)) return _getChainlinkPrice(usdOracle_);
        address ethOracle_ = _ethOracles[asset_];
        if (ethOracle_ == address(0)) revert NoOracle();
        uint256 ethPrice_ = _getChainlinkPrice(ethOracle_);
        uint256 ethUsdPrice_ = _getChainlinkPrice(_ethUsdOracle);
        return ethPrice_.mul(ethUsdPrice_);
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
            _addressProvider.leveragedTokenFactory().isLeveragedToken(token_);
    }

    function _exchangeRate(address token_) internal view returns (uint256) {
        return ILeveragedToken(token_).positionManager().exchangeRate();
    }
}
