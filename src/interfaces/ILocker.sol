// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ILocker {
    event Locked(
        address indexed accountFrom,
        address indexed accountTo,
        uint256 amount
    );
    event PreparedUnlock(address indexed account);
    event Unlocked(
        address indexed accountFrom,
        address indexed accountTo,
        uint256 amount
    );
    event Relocked(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount);
    event DonatedRewards(address indexed account, uint256 amount);

    error ZeroAmount();
    error ZeroBalance();
    error AlreadyPreparedUnlock();
    error NoUnlockPrepared();
    error NotUnlocked();
    error UnlockPrepared();
    error ClaimingNotEnabled();
    error ClaimingAlreadyEnabled();

    /**
     * @notice Locks TLX tokens for the caller.
     * @param amount The amount of TLX tokens to lock.
     */
    function lock(uint256 amount) external;

    /**
     * @notice Locks TLX tokens for the caller for the account.
     * @param amount The amount of TLX tokens to lock.
     * @param account The account to lock the TLX tokens to.
     */
    function lockFor(uint256 amount, address account) external;

    /**
     * @notice Prepares the caller's locked TLX tokens for unlocking.
     */
    function prepareUnlock() external;

    /**
     * @notice Unlocks the caller's TLX tokens.
     */
    function unlock() external;

    /**
     * @notice Relocks the caller's prepared TLX tokens.
     */
    function relock() external;

    /**
     * @notice Unlocks the caller's TLX tokens for the given account.
     * @param account The account to send the TLX tokens to.
     */
    function unlockFor(address account) external;

    /**
     * @notice Claims the caller's rewards.
     */
    function claim() external;

    /**
     * @notice Donates an amount of the reward token to the locker.
     */
    function donateRewards(uint256 amount) external;

    /**
     * @notice Enables claiming for lockers.
     * @dev This can only be called by the owner.
     */
    function enableClaiming() external;

    /**
     * @notice Returns if claiming is enabled for lockers.
     * @return claimingEnabled Whether claiming is enabled for lockers.
     */
    function claimingEnabled() external view returns (bool claimingEnabled);

    /**
     * @notice Returns the amount of TLX tokens locked for the given account.
     * @param account The account to return the locked TLX tokens for.
     * @return amount The amount of TLX tokens locked for the given account.
     */
    function balanceOf(address account) external view returns (uint256 amount);

    /**
     * @notice Returns the total amount of TLX tokens locked.
     * @return amount The total amount of TLX tokens locked.
     */
    function totalLocked() external view returns (uint256 amount);

    /**
     * @notice Returns the total amount of TLX tokens prepared for unlocking.
     * @return amount The total amount of TLX tokens prepared for unlocking.
     */
    function totalPrepared() external view returns (uint256 amount);

    /**
     * @notice Returns the amount of reward tokens claimable for the given account.
     * @param account The account to return the claimable reward tokens for.
     * @return amount The amount of reward tokens claimable for the given account.
     */
    function claimable(address account) external view returns (uint256 amount);

    /**
     * @notice Returns the timestamp for when the given account's TLX tokens are unlocked.
     * @dev Returns 0 if the account's TLX tokens are not prepared for unlocking.
     * @param account The account to return the unlock time for.
     * @return time The timestamp for when the given account's TLX tokens are unlocked.
     */
    function unlockTime(address account) external view returns (uint256 time);

    /**
     * @notice Returns whether the given account's TLX tokens are unlocked.
     * @param account The account to return whether the TLX tokens are unlocked for.
     * @return unlocked Whether the given account's TLX tokens are unlocked.
     */
    function isUnlocked(address account) external view returns (bool);

    /**
     * @notice Returns the symbol of the Locker.
     * @return symbol The symbol of the Locker.
     */
    function symbol() external view returns (string memory symbol);

    /**
     * @notice Returns the name of the Locker.
     * @return name The name of the Locker.
     */
    function name() external view returns (string memory name);

    /**
     * @notice Returns the number of decimals the Locker's token uses.
     * @return decimals The number of decimals the Locker's token uses.
     */
    function decimals() external view returns (uint8 decimals);

    /**
     * @notice Returns the delay the user must wait when unlocking.
     * @return delay The delay the user must wait when unlocking.
     */
    function unlockDelay() external view returns (uint256 delay);

    /**
     * @notice Returns the address of the reward token.
     * @return rewardToken The address of the reward token.
     */
    function rewardToken() external view returns (address rewardToken);
}
