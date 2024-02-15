// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import {AddressKeys} from "./libraries/AddressKeys.sol";
import {Errors} from "./libraries/Errors.sol";

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ILeveragedTokenFactory} from "./interfaces/ILeveragedTokenFactory.sol";
import {IReferrals} from "./interfaces/IReferrals.sol";
import {IAirdrop} from "./interfaces/IAirdrop.sol";
import {IBonding} from "./interfaces/IBonding.sol";
import {IGenesisLocker} from "./interfaces/IGenesisLocker.sol";
import {IVesting} from "./interfaces/IVesting.sol";
import {ITlxToken} from "./interfaces/ITlxToken.sol";
import {IStaker} from "./interfaces/IStaker.sol";
import {ISynthetixHandler} from "./interfaces/ISynthetixHandler.sol";
import {IParameterProvider} from "./interfaces/IParameterProvider.sol";
import {IZapSwap} from "./interfaces/IZapSwap.sol";

contract AddressProvider is IAddressProvider, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => address) internal _addresses;
    mapping(bytes32 => bool) internal _frozenAddresses;
    EnumerableSet.AddressSet internal _rebalancer;

    /// @inheritdoc IAddressProvider
    function updateAddress(
        bytes32 key_,
        address value_
    ) external override onlyOwner {
        if (_frozenAddresses[key_]) revert AddressIsFrozen(key_);
        if (value_ == address(0)) revert Errors.ZeroAddress();
        if (value_ == _addresses[key_]) revert Errors.SameAsCurrent();
        _addresses[key_] = value_;
        emit AddressUpdated(key_, value_);
    }

    /// @inheritdoc IAddressProvider
    function freezeAddress(bytes32 key_) external override onlyOwner {
        if (_frozenAddresses[key_]) revert AddressIsFrozen(key_);
        _frozenAddresses[key_] = true;
        emit AddressFrozen(key_);
    }

    /// @inheritdoc IAddressProvider
    function addRebalancer(address account_) external override onlyOwner {
        _rebalancer.add(account_);
        emit RebalancerAdded(account_);
    }

    /// @inheritdoc IAddressProvider
    function removeRebalancer(address account_) external override onlyOwner {
        _rebalancer.remove(account_);
        emit RebalancerRemoved(account_);
    }

    /// @inheritdoc IAddressProvider
    function addressOf(bytes32 key_) external view override returns (address) {
        return _addresses[key_];
    }

    /// @inheritdoc IAddressProvider
    function isAddressFrozen(bytes32 key_) external view returns (bool) {
        return _frozenAddresses[key_];
    }

    /// @inheritdoc IAddressProvider
    function leveragedTokenFactory()
        external
        view
        override
        returns (ILeveragedTokenFactory)
    {
        return
            ILeveragedTokenFactory(
                _getAddress(AddressKeys.LEVERAGED_TOKEN_FACTORY)
            );
    }

    /// @inheritdoc IAddressProvider
    function referrals() external view override returns (IReferrals) {
        return IReferrals(_getAddress(AddressKeys.REFERRALS));
    }

    /// @inheritdoc IAddressProvider
    function airdrop() external view override returns (IAirdrop) {
        return IAirdrop(_getAddress(AddressKeys.AIRDROP));
    }

    /// @inheritdoc IAddressProvider
    function bonding() external view override returns (IBonding) {
        return IBonding(_getAddress(AddressKeys.BONDING));
    }

    /// @inheritdoc IAddressProvider
    function treasury() external view override returns (address) {
        return _getAddress(AddressKeys.TREASURY);
    }

    /// @inheritdoc IAddressProvider
    function vesting() external view override returns (IVesting) {
        return IVesting(_getAddress(AddressKeys.VESTING));
    }

    /// @inheritdoc IAddressProvider
    function tlx() external view override returns (ITlxToken) {
        return ITlxToken(_getAddress(AddressKeys.TLX));
    }

    /// @inheritdoc IAddressProvider
    function staker() external view override returns (IStaker) {
        return IStaker(_getAddress(AddressKeys.STAKER));
    }

    /// @inheritdoc IAddressProvider
    function baseAsset() external view override returns (IERC20Metadata) {
        return IERC20Metadata(_getAddress(AddressKeys.BASE_ASSET));
    }

    /// @inheritdoc IAddressProvider
    function zapSwap() external view override returns (IZapSwap) {
        return IZapSwap(_getAddress(AddressKeys.ZAP_SWAP));
    }

    /// @inheritdoc IAddressProvider
    function synthetixHandler()
        external
        view
        override
        returns (ISynthetixHandler)
    {
        return ISynthetixHandler(_getAddress(AddressKeys.SYNTHETIX_HANDLER));
    }

    /// @inheritdoc IAddressProvider
    function pol() external view override returns (address) {
        return _getAddress(AddressKeys.POL);
    }

    /// @inheritdoc IAddressProvider
    function parameterProvider()
        external
        view
        override
        returns (IParameterProvider)
    {
        return IParameterProvider(_getAddress(AddressKeys.PARAMETER_PROVIDER));
    }

    /// @inheritdoc IAddressProvider
    function isRebalancer(
        address account_
    ) external view override returns (bool) {
        return _rebalancer.contains(account_);
    }

    /// @inheritdoc IAddressProvider
    function rebalancers() external view override returns (address[] memory) {
        return _rebalancer.values();
    }

    /// @inheritdoc IAddressProvider
    function rebalanceFeeReceiver() external view override returns (address) {
        return _getAddress(AddressKeys.REBALANCE_FEE_RECEIVER);
    }

    function _getAddress(bytes32 key_) internal view returns (address) {
        address value_ = _addresses[key_];
        if (value_ == address(0)) revert Errors.ZeroAddress();
        return value_;
    }
}
