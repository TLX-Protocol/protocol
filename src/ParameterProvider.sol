// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {EnumerableMap} from "openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";

import {Errors} from "./libraries/Errors.sol";

import {IParameterProvider} from "./interfaces/IParameterProvider.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

import {ParameterKeys} from "./libraries/ParameterKeys.sol";

contract ParameterProvider is IParameterProvider, Ownable {
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;

    uint256 internal constant _MIN_REBALANCE_THRESHOLD = 0.01e18;
    uint256 internal constant _MAX_REBALANCE_THRESHOLD = 0.8e18;

    IAddressProvider internal _addressProvider;
    EnumerableMap.Bytes32ToUintMap internal _parameters;
    mapping(address => uint256) internal _rebalanceThresholds;

    modifier onlyOwnerOrFactory() {
        if (
            msg.sender != owner() &&
            msg.sender != address(_addressProvider.leveragedTokenFactory())
        ) {
            revert Errors.NotAuthorized();
        }
        _;
    }

    constructor(address addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
    }

    /// @inheritdoc IParameterProvider
    function updateParameter(
        bytes32 key_,
        uint256 value_
    ) external override onlyOwner {
        if (_parameters.contains(key_)) {
            if (_parameters.get(key_) == value_) revert Errors.SameAsCurrent();
        }
        _parameters.set(key_, value_);
        emit ParameterUpdated(key_, value_);
    }

    /// @inheritdoc IParameterProvider
    function updateRebalanceThreshold(
        address leveragedToken_,
        uint256 value_
    ) external override onlyOwnerOrFactory {
        uint256 oldValue_ = _rebalanceThresholds[leveragedToken_];
        if (oldValue_ == value_) revert Errors.SameAsCurrent();

        if (value_ < _MIN_REBALANCE_THRESHOLD) {
            revert InvalidRebalanceThreshold();
        }
        if (value_ > _MAX_REBALANCE_THRESHOLD) {
            revert InvalidRebalanceThreshold();
        }

        _rebalanceThresholds[leveragedToken_] = value_;
        emit RebalanceThresholdUpdated(leveragedToken_, value_);
    }

    /// @inheritdoc IParameterProvider
    function parameterOf(
        bytes32 key_
    ) external view override returns (uint256) {
        return _getParameter(key_);
    }

    /// @inheritdoc IParameterProvider
    function redemptionFee() external view override returns (uint256) {
        return _getParameter(ParameterKeys.REDEMPTION_FEE);
    }

    /// @inheritdoc IParameterProvider
    function streamingFee() external view override returns (uint256) {
        return _getParameter(ParameterKeys.STREAMING_FEE);
    }

    /// @inheritdoc IParameterProvider
    function rebalanceFee() external view override returns (uint256) {
        return _getParameter(ParameterKeys.REBALANCE_FEE);
    }

    /// @inheritdoc IParameterProvider
    function parameters() external view override returns (Parameter[] memory) {
        uint256 length = _parameters.length();
        Parameter[] memory _params = new Parameter[](length);
        for (uint256 i = 0; i < length; i++) {
            (bytes32 key, uint256 value) = _parameters.at(i);
            _params[i] = Parameter(key, value);
        }
        return _params;
    }

    /// @inheritdoc IParameterProvider
    function rebalanceThreshold(
        address leveragedToken_
    ) external view override returns (uint256) {
        return _rebalanceThresholds[leveragedToken_];
    }

    function _getParameter(bytes32 key_) internal view returns (uint256) {
        if (!_parameters.contains(key_)) revert NonExistentParameter(key_);
        return _parameters.get(key_);
    }
}
