// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {TlxOwnable} from "./utils/TlxOwnable.sol";
import {ITlxUpkeepRegistry} from "./interfaces/ITlxUpkeepRegistry.sol";

contract TlxUpkeepRegistry is ITlxUpkeepRegistry, TlxOwnable {
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet internal _upkeepIDs;
    mapping(uint256 => Upkeep) internal _upkeepInfos;

    constructor(address addressProvider_) TlxOwnable(addressProvider_) {}

    /// @inheritdoc ITlxUpkeepRegistry

    function addUpkeep(
        Upkeep calldata upkeepInfo_
    ) external override onlyOwner {
        bool added_ = _upkeepIDs.add(upkeepInfo_.id);
        _upkeepInfos[upkeepInfo_.id] = upkeepInfo_;
        if (added_)
            emit UpkeepAdded(
                upkeepInfo_.id,
                upkeepInfo_.registryAddress,
                upkeepInfo_.upkeepAddress
            );
    }

    /// @inheritdoc ITlxUpkeepRegistry
    function removeUpkeep(uint256 upkeepID_) external override onlyOwner {
        bool removed_ = _upkeepIDs.remove(upkeepID_);
        delete _upkeepInfos[upkeepID_];
        if (removed_) emit UpkeepRemoved(upkeepID_);
    }

    /// @inheritdoc ITlxUpkeepRegistry
    function isUpkeep(uint256 upkeepID_) external view override returns (bool) {
        return _upkeepIDs.contains(upkeepID_);
    }

    /// @inheritdoc ITlxUpkeepRegistry
    function allUpkeepIDs() external view override returns (uint256[] memory) {
        return _upkeepIDs.values();
    }

    /// @inheritdoc ITlxUpkeepRegistry
    function upkeepInfoForID(
        uint256 upkeepID_
    ) external view override returns (Upkeep memory) {
        return _upkeepInfos[upkeepID_];
    }

    /// @inheritdoc ITlxUpkeepRegistry
    function allUpkeepIDsAndInfo()
        external
        view
        override
        returns (Upkeep[] memory upkeepInfos_)
    {
        uint256[] memory upkeepIDs_ = _upkeepIDs.values();
        upkeepInfos_ = new Upkeep[](upkeepIDs_.length);
        for (uint256 i_; i_ < upkeepIDs_.length; i_++) {
            upkeepInfos_[i_] = _upkeepInfos[upkeepIDs_[i_]];
        }
    }
}
