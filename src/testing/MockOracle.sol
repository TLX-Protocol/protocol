// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "../libraries/ScaledNumber.sol";

import {IOracle} from "../interfaces/IOracle.sol";

interface IMockOracle is IOracle {
    function setPrice(string calldata asset_, uint256 price_) external;
}

contract MockOracle is IMockOracle {
    using ScaledNumber for uint256;

    mapping(string => uint256) internal _prices;

    constructor() {}

    function setPrice(string calldata asset_, uint256 price_) external {
        _prices[asset_] = price_;
    }

    function getPrice(
        string calldata asset_
    ) external view override returns (uint256) {
        if (_prices[asset_] == 0) return 1e18;
        return _prices[asset_];
    }
}
