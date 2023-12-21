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

    event Claimed(address indexed account, address indexed to, uint256 amount);
    event DelegateAdded(address indexed account, address indexed delegate);
    event DelegateRemoved(address indexed account, address indexed delegate);

    error NothingToClaim();
    error InvalidDuration();
    error NotAuthorized();

    /**
     * @notice Claim vested tokens.
     */
    function claim() external;

    /**
     * @notice Claim vested tokens for 'account' and send to 'to'.
     * @param account The address to claim the vested tokens for.
     * @param to The address to send the claimed tokens to.
     */
    function claim(address account, address to) external;

    /**
     * @notice Adds a delegate for the caller.
     * @param delegate The address of the delegate to add.
     */
    function addDelegate(address delegate) external;

    /**
     * @notice Removes a delegate for the caller.
     * @param delegate The address of the delegate to remove.
     */
    function removeDelegate(address delegate) external;

    /**
     * @notice Get the amount of tokens that were allocated for vesting for `account`.
     * @param account The address to get the allocated amount for.
     * @return amount The amount of tokens allocated for vesting for `account`.
     */
    function allocated(address account) external view returns (uint256 amount);

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

    /**
     * @notice Check if `delegate` is a delegate for `account`.
     * @param account The address to check the delegate for.
     * @param delegate The address to check if it is a delegate.
     * @return isDelegate True if `delegate` is a delegate for `account`.
     */
    function isDelegate(
        address account,
        address delegate
    ) external view returns (bool isDelegate);
}
