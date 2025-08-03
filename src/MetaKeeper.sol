// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {AutomationCompatibleInterface} from "chainlink/src/v0.8/automation/AutomationCompatible.sol";
import {IAutomationRegistryConsumer} from "chainlink/src/v0.8/automation/interfaces/IAutomationRegistryConsumer.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TlxOwnable} from "./utils/TlxOwnable.sol";

import {Errors} from "./libraries/Errors.sol";
import {AddressKeys} from "./libraries/AddressKeys.sol";
import {ScaledNumber} from "./libraries/ScaledNumber.sol";

import {IMetaKeeper} from "./interfaces/IMetaKeeper.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ITlxUpkeepRegistry} from "./interfaces/ITlxUpkeepRegistry.sol";

contract MetaKeeper is IMetaKeeper, TlxOwnable {
    using ScaledNumber for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct MinBalance {
        address registryAddress;
        uint256 minBalance;
    }

    uint256 internal constant _MIN_BALANCE_BUFFER = 0.2e18;

    IAddressProvider internal immutable _addressProvider;

    uint256 public maxTopUps;
    IERC20 public topUpAsset;
    uint96 public topUpAmount;

    EnumerableSet.AddressSet internal _forwarderAddresses;

    constructor(
        address addressProvider_,
        uint256 maxTopUps_,
        address topUpAsset_,
        uint96 topUpAmount_
    ) TlxOwnable(addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
        maxTopUps = maxTopUps_;
        topUpAsset = IERC20(topUpAsset_);
        topUpAmount = topUpAmount_;
    }

    /// @inheritdoc AutomationCompatibleInterface
    function performUpkeep(bytes calldata performData_) external override {
        if (!_forwarderAddresses.contains(msg.sender)) revert NotForwarder();

        uint256[] memory upkeepsToTopup_ = abi.decode(
            performData_,
            (uint256[])
        );

        uint256 topUpCount_ = upkeepsToTopup_.length;
        if (topUpCount_ == 0) revert NoUpkeepsToTopUp();

        ITlxUpkeepRegistry tlxUpkeepRegistry_ = ITlxUpkeepRegistry(
            _addressProvider.addressOf(AddressKeys.UPKEEP_REGISTRY)
        );
        uint96 topUpAmount_ = topUpAmount;

        for (uint256 i_; i_ < topUpCount_; i_++) {
            uint256 upkeepID_ = upkeepsToTopup_[i_];
            if (!tlxUpkeepRegistry_.isUpkeep(upkeepID_)) {
                revert NotUpkeep();
            }
            ITlxUpkeepRegistry.Upkeep memory upkeepInfo_ = tlxUpkeepRegistry_
                .upkeepInfoForID(upkeepID_);
            IAutomationRegistryConsumer chainlinkRegistry_ = IAutomationRegistryConsumer(
                    upkeepInfo_.registryAddress
                );
            uint256 thresholdBalance_ = uint256(
                chainlinkRegistry_.getMinBalance(upkeepID_)
            ).mul(1e18 + _MIN_BALANCE_BUFFER);
            if (chainlinkRegistry_.getBalance(upkeepID_) > thresholdBalance_)
                revert UpkeepHasSufficientFunds();
            if (topUpAsset.balanceOf(address(this)) < uint256(topUpAmount_))
                revert OutOfFunds();

            topUpAsset.approve(address(chainlinkRegistry_), topUpAmount_);
            chainlinkRegistry_.addFunds(upkeepID_, topUpAmount_);

            emit UpkeepPerformed(upkeepID_);
        }
    }

    /// @inheritdoc IMetaKeeper
    function setMaxTopUps(uint256 maxTopUps_) external override onlyOwner {
        maxTopUps = maxTopUps_;
    }

    /// @inheritdoc IMetaKeeper
    function setTopUpAmount(uint96 topUpAmount_) external override onlyOwner {
        topUpAmount = topUpAmount_;
    }

    /// @inheritdoc IMetaKeeper
    function addForwarderAddress(
        address forwarderAddress_
    ) external override onlyOwner {
        if (!_forwarderAddresses.add(forwarderAddress_)) {
            revert Errors.AlreadyExists();
        }
    }

    /// @inheritdoc IMetaKeeper
    function removeForwarderAddress(
        address forwarderAddress_
    ) external override onlyOwner {
        if (!_forwarderAddresses.remove(forwarderAddress_)) {
            revert Errors.DoesNotExist();
        }
    }

    /// @inheritdoc IMetaKeeper
    function recoverAsset(
        address receiver,
        address asset,
        uint256 amount
    ) external override onlyOwner {
        IERC20 token = IERC20(asset);
        token.transfer(receiver, amount);
        emit AssetRecovered(asset, receiver, amount);
    }

    /// @inheritdoc IMetaKeeper
    function forwarderAddresses()
        external
        view
        override
        returns (address[] memory)
    {
        return _forwarderAddresses.values();
    }

    /// @inheritdoc AutomationCompatibleInterface
    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        ITlxUpkeepRegistry tlxUpkeepRegistry_ = ITlxUpkeepRegistry(
            _addressProvider.addressOf(AddressKeys.UPKEEP_REGISTRY)
        );
        ITlxUpkeepRegistry.Upkeep[] memory upkeeps_ = tlxUpkeepRegistry_
            .allUpkeepIDsAndInfo();
        MinBalance[] memory minBalances_ = _getMinBalances(upkeeps_);

        uint256 maxTopUps_ = maxTopUps;
        uint256[] memory upkeepsToTopup_ = new uint256[](maxTopUps_);
        uint256 topUpsCount_;
        IAutomationRegistryConsumer chainlinkRegistry_;
        for (uint256 i_; i_ < upkeeps_.length; i_++) {
            uint256 upkeepID_ = upkeeps_[i_].id;
            chainlinkRegistry_ = IAutomationRegistryConsumer(
                upkeeps_[i_].registryAddress
            );
            uint256 thresholdBalance_ = _findMinBalance(
                minBalances_,
                upkeeps_[i_].registryAddress
            ).mul(1e18 + _MIN_BALANCE_BUFFER);
            if (chainlinkRegistry_.getBalance(upkeepID_) > thresholdBalance_)
                continue;
            upkeepsToTopup_[topUpsCount_] = upkeepID_;
            topUpsCount_++;
            if (topUpsCount_ == maxTopUps_) break;
        }

        if (
            topUpsCount_ == 0 ||
            topUpAsset.balanceOf(address(this)) < uint256(topUpAmount)
        ) return (false, "");
        upkeepNeeded = true;

        // solhint-disable-next-line
        assembly {
            mstore(upkeepsToTopup_, topUpsCount_)
        }
        performData = abi.encode(upkeepsToTopup_);
    }

    function _getMinBalances(
        ITlxUpkeepRegistry.Upkeep[] memory upkeeps_
    ) internal view returns (MinBalance[] memory minBalances_) {
        minBalances_ = new MinBalance[](upkeeps_.length);
        uint256 count;
        for (uint256 i_; i_ < upkeeps_.length; i_++) {
            bool exists;
            for (uint256 j_; j_ < count; j_++) {
                if (
                    upkeeps_[i_].registryAddress ==
                    minBalances_[j_].registryAddress
                ) {
                    exists = true;
                    break;
                }
            }
            if (exists) continue;

            uint256 minBalance_ = IAutomationRegistryConsumer(
                upkeeps_[i_].registryAddress
            ).getMinBalance(upkeeps_[i_].id);
            minBalances_[i_] = MinBalance({
                registryAddress: upkeeps_[i_].registryAddress,
                minBalance: minBalance_
            });
            count++;
        }

        // solhint-disable-next-line
        assembly {
            mstore(minBalances_, count)
        }
    }

    function _findMinBalance(
        MinBalance[] memory minBalances_,
        address registryAddress_
    ) internal pure returns (uint256 minBalance_) {
        for (uint256 i_; i_ < minBalances_.length; i_++) {
            if (minBalances_[i_].registryAddress == registryAddress_) {
                minBalance_ = minBalances_[i_].minBalance;
                break;
            }
        }
    }
}
