// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {ILeveragedTokenFactory} from "./ILeveragedTokenFactory.sol";
import {IOracle} from "./IOracle.sol";
import {IReferrals} from "./IReferrals.sol";
import {IAirdrop} from "./IAirdrop.sol";
import {IBonding} from "./IBonding.sol";
import {IVesting} from "./IVesting.sol";
import {ITlxToken} from "./ITlxToken.sol";
import {ILocker} from "./ILocker.sol";
import {ISynthetixHandler} from "./ISynthetixHandler.sol";

interface IAddressProvider {
    event AddressUpdated(bytes32 indexed key, address value);

    /**
     * @notice Updates an address for the given key.
     * @param key The key of the address to be updated.
     * @param value The value of the address to be updated.
     */
    function updateAddress(bytes32 key, address value) external;

    /**
     * @notice Returns the address for a kiven key.
     * @param key The key of the address to be returned.
     * @return value The address for the given key.
     */
    function addressOf(bytes32 key) external view returns (address value);

    /**
     * @notice Returns the LeveragedTokenFactory contract.
     * @return leveragedTokenFactory The LeveragedTokenFactory contract.
     */
    function leveragedTokenFactory()
        external
        view
        returns (ILeveragedTokenFactory leveragedTokenFactory);

    /**
     * @notice Returns the Oracle contract.
     * @return oracle The Oracle contract.
     */
    function oracle() external view returns (IOracle oracle);

    /**
     * @notice Returns the Referrals contract.
     * @return referrals The Referrals contract.
     */
    function referrals() external view returns (IReferrals referrals);

    /**
     * @notice Returns the Airdrop contract.
     * @return airdrop The Airdrop contract.
     */
    function airdrop() external view returns (IAirdrop airdrop);

    /**
     * @notice Returns the Bonding contract.
     * @return bonding The Bonding contract.
     */
    function bonding() external view returns (IBonding bonding);

    /**
     * @notice Returns the address for the Treasury contract.
     * @return treasury The address of the Treasury contract.
     */
    function treasury() external view returns (address treasury);

    /**
     * @notice Returns the Vesting contract.
     * @return vesting The Vesting contract.
     */
    function vesting() external view returns (IVesting vesting);

    /**
     * @notice Returns the TLX contract.
     * @return tlx The TLX contract.
     */
    function tlx() external view returns (ITlxToken tlx);

    /**
     * @notice Returns the Locker contract.
     * @return locker The Locker contract.
     */
    function locker() external view returns (ILocker locker);

    /**
     * @notice Returns the base asset.
     * @return baseAsset The base asset.
     */
    function baseAsset() external view returns (IERC20Metadata baseAsset);

    /**
     * @notice Returns the SynthetixHandler contract.
     * @return synthetixHandler The SynthetixHandler  contract.
     */
    function synthetixHandler()
        external
        view
        returns (ISynthetixHandler synthetixHandler);

    /**
     * @notice Returns the address for the POL token.
     * @return pol The address of the POL token.
     */
    function pol() external view returns (address pol);
}
