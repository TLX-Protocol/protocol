// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IVesting {
    struct VestingAmount {
        address account;
        uint256 amount;
    }

    struct VestingData {
        uint256 amount;
        uint256 claimed;
    }

    event Claimed(address indexed account, uint256 amount);

    error NothingToClaim();
    error InvalidDuration();

    /**
     * @notice Claim vested tokens.
     */
    function claim() external;

    /**
     * @notice Get the amount of tokens that have vested for `account`.
     * @param account The address to get the vested amount for.
     * @return amount The amount of tokens vested to `account`.
     */
    function vested(address account) external view returns (uint256 amount);

    /**
     * @notice Get the amount of tokens that are vesting for `account`.
     * @param account The address to get the vesting amount for.
     * @return amount The amount of tokens vesting for `account`.
     */
    function vesting(address account) external view returns (uint256 amount);

    /**
     * @notice Get the amount of tokens that have been claimed for `account`.
     * @param account The address to get the claimed amount for.
     * @return amount The amount of tokens claimed for `account`.
     */
    function claimed(address account) external view returns (uint256 amount);

    /**
     * @notice Get the amount of tokens that are claimable for `account`.
     * @dev This is calculated as `vested` - `claimed`.
     * @param account The address to get the claimable amount for.
     * @return amount The amount of tokens claimable for `account`.
     */
    function claimable(address account) external view returns (uint256 amount);
}
