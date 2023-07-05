// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {Tokens} from "./libraries/Tokens.sol";

import {IPositionManagerFactory} from "./interfaces/IPositionManagerFactory.sol";
import {PositionManager} from "./PositionManager.sol";

contract PositionManagerFactory is IPositionManagerFactory, Ownable {
    address[] internal _positionManagers;
    mapping(address => address) internal _positionManager;

    function createPositionManager(
        address targetAsset_
    ) external override onlyOwner returns (address) {
        if (_positionManager[targetAsset_] == address(0))
            revert AlreadyExists();

        address positionManager_ = address(
            new PositionManager(Tokens.USDC, targetAsset_)
        );
        _positionManagers.push(positionManager_);
        _positionManager[targetAsset_] = positionManager_;
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
