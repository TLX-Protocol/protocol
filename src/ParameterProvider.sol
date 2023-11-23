// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {IParameterProvider} from "./interfaces/IParameterProvider.sol";

import {ParameterKeys} from "./libraries/ParameterKeys.sol";

contract ParameterProvider is IParameterProvider, Ownable {
    mapping(bytes32 => uint256) internal _parameters;

    function updateParameter(
        bytes32 key_,
        uint256 value_
    ) external override onlyOwner {
        _parameters[key_] = value_;
        emit ParameterUpdated(key_, value_);
    }

    function parameterOf(
        bytes32 key_
    ) external view override returns (uint256) {
        return _parameters[key_];
    }

    function redemptionFee() external view override returns (uint256) {
        return _parameters[ParameterKeys.REDEMPTION_FEE];
    }

    function streamingFee() external view override returns (uint256) {
        return _parameters[ParameterKeys.STREAMING_FEE];
    }
}
