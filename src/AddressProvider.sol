// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {AddressKeys} from "./libraries/AddressKeys.sol";

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ILeveragedTokenFactory} from "./interfaces/ILeveragedTokenFactory.sol";
import {IReferrals} from "./interfaces/IReferrals.sol";
import {IAirdrop} from "./interfaces/IAirdrop.sol";
import {IBonding} from "./interfaces/IBonding.sol";
import {IVesting} from "./interfaces/IVesting.sol";
import {ITlxToken} from "./interfaces/ITlxToken.sol";
import {ILocker} from "./interfaces/ILocker.sol";
import {ISynthetixHandler} from "./interfaces/ISynthetixHandler.sol";
import {IParameterProvider} from "./interfaces/IParameterProvider.sol";

contract AddressProvider is IAddressProvider, Ownable {
    mapping(bytes32 => address) internal _addresses;
    mapping(bytes32 => bool) internal _frozenAddresses;

    function updateAddress(
        bytes32 key_,
        address value_
    ) external override onlyOwner {
        if (_frozenAddresses[key_]) revert AddressIsFrozen(key_);
        _addresses[key_] = value_;
        emit AddressUpdated(key_, value_);
    }

    function freezeAddress(bytes32 key_) external override onlyOwner {
        if (_frozenAddresses[key_]) revert AddressIsFrozen(key_);
        _frozenAddresses[key_] = true;
        emit AddressFrozen(key_);
    }

    function addressOf(bytes32 key_) external view override returns (address) {
        return _addresses[key_];
    }

    function isAddressFrozen(bytes32 key_) external view returns (bool) {
        return _frozenAddresses[key_];
    }

    function leveragedTokenFactory()
        external
        view
        override
        returns (ILeveragedTokenFactory)
    {
        return
            ILeveragedTokenFactory(
                _addresses[AddressKeys.LEVERAGED_TOKEN_FACTORY]
            );
    }

    function referrals() external view override returns (IReferrals) {
        return IReferrals(_addresses[AddressKeys.REFERRALS]);
    }

    function airdrop() external view override returns (IAirdrop) {
        return IAirdrop(_addresses[AddressKeys.AIRDROP]);
    }

    function bonding() external view override returns (IBonding) {
        return IBonding(_addresses[AddressKeys.BONDING]);
    }

    function treasury() external view override returns (address) {
        return _addresses[AddressKeys.TREASURY];
    }

    function vesting() external view override returns (IVesting) {
        return IVesting(_addresses[AddressKeys.VESTING]);
    }

    function tlx() external view override returns (ITlxToken) {
        return ITlxToken(_addresses[AddressKeys.TLX]);
    }

    function locker() external view override returns (ILocker) {
        return ILocker(_addresses[AddressKeys.LOCKER]);
    }

    function baseAsset() external view override returns (IERC20Metadata) {
        return IERC20Metadata(_addresses[AddressKeys.BASE_ASSET]);
    }

    function synthetixHandler()
        external
        view
        override
        returns (ISynthetixHandler)
    {
        return ISynthetixHandler(_addresses[AddressKeys.SYNTHETIX_HANDLER]);
    }

    function pol() external view override returns (address) {
        return _addresses[AddressKeys.POL];
    }

    function parameterProvider()
        external
        view
        override
        returns (IParameterProvider)
    {
        return IParameterProvider(_addresses[AddressKeys.PARAMETER_PROVIDER]);
    }
}
