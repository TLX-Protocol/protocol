// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {ILeveragedTokenFactory} from "./ILeveragedTokenFactory.sol";
import {IReferrals} from "./IReferrals.sol";
import {IAirdrop} from "./IAirdrop.sol";
import {IBonding} from "./IBonding.sol";
import {IVesting} from "./IVesting.sol";
import {ITlxToken} from "./ITlxToken.sol";
import {IStaker} from "./IStaker.sol";
import {ISynthetixHandler} from "./ISynthetixHandler.sol";
import {IParameterProvider} from "./IParameterProvider.sol";
import {IZapSwap} from "./IZapSwap.sol";

interface IAddressProvider {
    event AddressUpdated(bytes32 indexed key, address value);
    event AddressFrozen(bytes32 indexed key);
    event RebalancerAdded(address indexed account);
    event RebalancerRemoved(address indexed account);

    error AddressIsFrozen(bytes32 key);

    /**
     * @notice Updates an address for the given key.
     * @param key The key of the address to be updated.
     * @param value The value of the address to be updated.
     */
    function updateAddress(bytes32 key, address value) external;

    /**
     * @notice Freezes an address for the given key, making it immutable.
     * @param key The key of the address to be frozen.
     */
    function freezeAddress(bytes32 key) external;

    /**
     * @notice Gives the `account` permissions to rebalance leveraged tokens.
     * @dev Reverts if the `account` is already a rebalancer.
     * @param account The address of the account to be added.
     */
    function addRebalancer(address account) external;

    /**
     * @notice Removes the `account` permissions to rebalance leveraged tokens.
     * @dev Reverts if the `account` is not a rebalancer.
     * @param account The address of the account to be removed.
     */
    function removeRebalancer(address account) external;

    /**
     * @notice Returns the address for a kiven key.
     * @param key The key of the address to be returned.
     * @return value The address for the given key.
     */
    function addressOf(bytes32 key) external view returns (address value);

    /**
     * @notice Returns whether an address is frozen.
     * @param key The key of the address to be checked.
     * @return Whether the address is frozen.
     */
    function isAddressFrozen(bytes32 key) external view returns (bool);

    /**
     * @notice Returns the LeveragedTokenFactory contract.
     * @return leveragedTokenFactory The LeveragedTokenFactory contract.
     */
    function leveragedTokenFactory()
        external
        view
        returns (ILeveragedTokenFactory leveragedTokenFactory);

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
     * @notice Returns the Staker contract.
     * @return staker The Staker contract.
     */
    function staker() external view returns (IStaker staker);

    /**
     * @notice Returns the ZapSwap contract.
     * @return zapSwap The ZapSwap contract.
     */
    function zapSwap() external view returns (IZapSwap zapSwap);

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

    /**
     * @notice Returns the Parameter Provider contract.
     * @return parameterProvider The Parameter Provider contract.
     */
    function parameterProvider()
        external
        view
        returns (IParameterProvider parameterProvider);

    /**
     * @notice Returns if the given `account` is permitted to rebalance leveraged tokens.
     * @param account The address of the account to be checked.
     * @return isRebalancer Whether the account is permitted to rebalance leveraged tokens.
     */
    function isRebalancer(
        address account
    ) external view returns (bool isRebalancer);

    /**
     * @notice Returns the list of rebalancers.
     * @return rebalancers The list of rebalancers.
     */
    function rebalancers() external view returns (address[] memory rebalancers);

    /**
     * @notice Returns the address for the Rebalance Fee Receiver.
     * @return rebalanceFeeReceiver The address of the Rebalance Fee Receiver.
     */
    function rebalanceFeeReceiver()
        external
        view
        returns (address rebalanceFeeReceiver);

    /**
     * @notice Returns the owner of all TLX contracts.
     * @return owner The owner of all TLX contracts.
     */
    function owner() external view returns (address owner);
}
