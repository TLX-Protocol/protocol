// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IOwnable {
    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @param newOwner The account to transfer ownership to.
     */
    function transferOwnership(address newOwner) external;
}
