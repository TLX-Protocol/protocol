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
     * @notice Returns the address for the Referrals contract.
     * @return referrals The address of the Referrals contract.
     */
    function referrals() external view returns (address referrals);

    /**
     * @notice Returns the address for the base asset.
     * @return baseAsset The address of the base asset.
     */
    function baseAsset() external view returns (address baseAsset);

    /**
     * @notice Returns the address for the DerivativesHandler contract.
     * @return derivativesHandler The address of the DerivativesHandler contract.
     */
    function derivativesHandler()
        external
        view
        returns (address derivativesHandler);
}
