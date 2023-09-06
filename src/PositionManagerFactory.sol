// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {Tokens} from "./libraries/Tokens.sol";

import {IPositionManagerFactory} from "./interfaces/IPositionManagerFactory.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {PositionManager} from "./PositionManager.sol";

contract PositionManagerFactory is IPositionManagerFactory, Ownable {
    address[] internal _positionManagers;
    mapping(address => address) internal _positionManager;
    address internal immutable _addressProvider;

    mapping(address => bool) public override isPositionManager;

    constructor(address addressProvider_) {
        _addressProvider = addressProvider_;
    }

    function createPositionManager(
        address targetAsset_
    ) external override onlyOwner returns (address) {
        // Checks
        if (_positionManager[targetAsset_] != address(0))
            revert AlreadyExists();
        IAddressProvider addressProvider_ = IAddressProvider(_addressProvider);
        IOracle oracle_ = IOracle(addressProvider_.oracle());
        if (oracle_.getUsdPrice(targetAsset_) == 0) revert NoOracle();

        // Deploying position manager
        address positionManager_ = address(
            new PositionManager(_addressProvider, Tokens.USDC, targetAsset_)
        );

        // Updating state
        isPositionManager[positionManager_] = true;
        _positionManagers.push(positionManager_);
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
        return _positionManagers;
    }

    function positionManager(
        address targetAsset_
    ) external view override returns (address) {
        return _positionManager[targetAsset_];
    }
}
