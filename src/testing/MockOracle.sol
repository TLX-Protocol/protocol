// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ScaledNumber} from "../libraries/ScaledNumber.sol";

import {IOracle} from "../interfaces/IOracle.sol";

interface IMockOracle is IOracle {
    function setPrice(address token_, uint256 price_) external;
}

contract MockOracle is IMockOracle {
    using ScaledNumber for uint256;

    mapping(address => uint256) internal _prices;

    constructor() {}

    function setPrice(address token_, uint256 price_) external {
        _prices[token_] = price_;
    }

    function getUsdPrice(
        address token_
    ) external view override returns (uint256) {
        if (_prices[token_] == 0) return 1e18;
        return _prices[token_];
    }
}
