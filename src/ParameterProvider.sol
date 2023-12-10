// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {EnumerableMap} from "openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";

import {IParameterProvider} from "./interfaces/IParameterProvider.sol";

import {ParameterKeys} from "./libraries/ParameterKeys.sol";

contract ParameterProvider is IParameterProvider, Ownable {
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;

    EnumerableMap.Bytes32ToUintMap internal _parameters;

    function updateParameter(
        bytes32 key_,
        uint256 value_
    ) external override onlyOwner {
        _parameters.set(key_, value_);
        emit ParameterUpdated(key_, value_);
    }

    function parameterOf(
        bytes32 key_
    ) external view override returns (uint256) {
        return _parameters.get(key_);
    }

    function redemptionFee() external view override returns (uint256) {
        return _parameters.get(ParameterKeys.REDEMPTION_FEE);
    }

    function streamingFee() external view override returns (uint256) {
        return _parameters.get(ParameterKeys.STREAMING_FEE);
    }

    function parameters() external view override returns (Parameter[] memory) {
        uint256 length = _parameters.length();
        Parameter[] memory _params = new Parameter[](length);
        for (uint256 i = 0; i < length; i++) {
            (bytes32 key, uint256 value) = _parameters.at(i);
            _params[i] = Parameter(key, value);
        }
        return _params;
    }
}
