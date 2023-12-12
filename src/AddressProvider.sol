// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {AddressKeys} from "./libraries/AddressKeys.sol";
import {Errors} from "./libraries/Errors.sol";

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

    function updateAddress(
        bytes32 key_,
        address value_
    ) external override onlyOwner {
        if (value_ == address(0)) revert Errors.ZeroAddress();
        if (value_ == _addresses[key_]) revert Errors.SameAsCurrent();
        _addresses[key_] = value_;
        emit AddressUpdated(key_, value_);
    }

    function addressOf(bytes32 key_) external view override returns (address) {
        return _addresses[key_];
    }

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

    function referrals() external view override returns (IReferrals) {
        return IReferrals(_getAddress(AddressKeys.REFERRALS));
    }

    function airdrop() external view override returns (IAirdrop) {
        return IAirdrop(_getAddress(AddressKeys.AIRDROP));
    }

    function bonding() external view override returns (IBonding) {
        return IBonding(_getAddress(AddressKeys.BONDING));
    }

    function treasury() external view override returns (address) {
        return _getAddress(AddressKeys.TREASURY);
    }

    function vesting() external view override returns (IVesting) {
        return IVesting(_getAddress(AddressKeys.VESTING));
    }

    function tlx() external view override returns (ITlxToken) {
        return ITlxToken(_getAddress(AddressKeys.TLX));
    }

    function locker() external view override returns (ILocker) {
        return ILocker(_getAddress(AddressKeys.LOCKER));
    }

    function baseAsset() external view override returns (IERC20Metadata) {
        return IERC20Metadata(_getAddress(AddressKeys.BASE_ASSET));
    }

    function synthetixHandler()
        external
        view
        override
        returns (ISynthetixHandler)
    {
        return ISynthetixHandler(_getAddress(AddressKeys.SYNTHETIX_HANDLER));
    }

    function pol() external view override returns (address) {
        return _getAddress(AddressKeys.POL);
    }

    function parameterProvider()
        external
        view
        override
        returns (IParameterProvider)
    {
        return IParameterProvider(_getAddress(AddressKeys.PARAMETER_PROVIDER));
    }

    function _getAddress(bytes32 key_) internal view returns (address) {
        address value_ = _addresses[key_];
        if (value_ == address(0)) revert Errors.ZeroAddress();
        return value_;
    }
}
