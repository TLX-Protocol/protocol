// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

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
     * @notice Returns the address for the LeveragedTokenFactory contract.
     * @return leveragedTokenFactory The address of the LeveragedTokenFactory contract.
     */
    function leveragedTokenFactory()
        external
        view
        returns (address leveragedTokenFactory);

    /**
     * @notice Returns the address for the PositionManagerFactory contract.
     * @return positionManagerFactory The address of the PositionManagerFactory contract.
     */
    function positionManagerFactory()
        external
        view
        returns (address positionManagerFactory);

    /**
     * @notice Returns the address for the Oracle contract.
     * @return oracle The address of the Oracle contract.
     */
    function oracle() external view returns (address oracle);

    /**
     * @notice Returns the address for the Airdrop contract.
     * @return airdrop The address of the Airdrop contract.
     */
    function airdrop() external view returns (address airdrop);

    /**
     * @notice Returns the address for the Bonding contract.
     * @return bonding The address of the Bonding contract.
     */
    function bonding() external view returns (address bonding);

    /**
     * @notice Returns the address for the Treasury contract.
     * @return treasury The address of the Treasury contract.
     */
    function treasury() external view returns (address treasury);

    /**
     * @notice Returns the address for the Vesting contract.
     * @return vesting The address of the Vesting contract.
     */
    function vesting() external view returns (address vesting);

    /**
     * @notice Returns the address for the TLX contract.
     * @return tlx The address of the TLX contract.
     */
    function tlx() external view returns (address tlx);
}
