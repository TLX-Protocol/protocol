// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import {Tokens} from "./libraries/Tokens.sol";
import {Errors} from "./libraries/Errors.sol";

import {IPositionManagerFactory} from "./interfaces/IPositionManagerFactory.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {PositionManager} from "./PositionManager.sol";

contract PositionManagerFactory is IPositionManagerFactory, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _positionManagers;
    mapping(string => address) internal _positionManager;
    IAddressProvider internal immutable _addressProvider;

    constructor(address addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
    }

    function createPositionManager(
        string calldata targetAsset_
    ) external override onlyOwner returns (address) {
        // Checks
        if (_positionManager[targetAsset_] != address(0))
            revert Errors.AlreadyExists();
        if (_addressProvider.oracle().getPrice(targetAsset_) == 0)
            revert NoOracle();
        if (
            !_addressProvider.derivativesHandler().isAssetSupported(
                targetAsset_
            )
        ) revert AssetNotSupported();

        // Deploying position manager
        address positionManager_ = address(
            new PositionManager(address(_addressProvider), targetAsset_)
        );

        // Updating state
        _positionManagers.add(positionManager_);
        _positionManager[targetAsset_] = positionManager_;
        emit PositionManagerCreated(positionManager_);
        return positionManager_;
    }

    function positionManagers()
        external
        view
        override
        returns (address[] memory)
    {
        return _positionManagers.values();
    }

    function positionManager(
        string calldata targetAsset_
    ) external view override returns (address) {
        return _positionManager[targetAsset_];
    }

    function isPositionManager(
        address positionManager_
    ) external view override returns (bool) {
        return _positionManagers.contains(positionManager_);
    }
}
