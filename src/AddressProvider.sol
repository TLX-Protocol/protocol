// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {AddressKeys} from "./libraries/AddressKeys.sol";

import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {ILeveragedTokenFactory} from "./interfaces/ILeveragedTokenFactory.sol";
import {IPositionManagerFactory} from "./interfaces/IPositionManagerFactory.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IReferrals} from "./interfaces/IReferrals.sol";
import {IAirdrop} from "./interfaces/IAirdrop.sol";
import {IBonding} from "./interfaces/IBonding.sol";
import {IVesting} from "./interfaces/IVesting.sol";
import {ITlxToken} from "./interfaces/ITlxToken.sol";
import {ILocker} from "./interfaces/ILocker.sol";
import {ISynthetixHandler} from "./interfaces/ISynthetixHandler.sol";

contract AddressProvider is IAddressProvider, Ownable, Initializable {
    mapping(bytes32 => address) internal _addresses;

    function updateAddress(
        bytes32 key_,
        address value_
    ) external override onlyOwner {
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
                _addresses[AddressKeys.LEVERAGED_TOKEN_FACTORY]
            );
    }

    function positionManagerFactory()
        external
        view
        override
        returns (IPositionManagerFactory)
    {
        return
            IPositionManagerFactory(
                _addresses[AddressKeys.POSITION_MANAGER_FACTORY]
            );
    }

    function oracle() external view override returns (IOracle) {
        return IOracle(_addresses[AddressKeys.ORACLE]);
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
}
