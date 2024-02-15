// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IRewardsStreaming} from "./IRewardsStreaming.sol";

interface IGenesisLocker is IRewardsStreaming {
    event Locked(address indexed account, uint256 amount);
    event Migrated(
        address indexed account,
        address indexed receiver,
        uint256 amount
    );
    event Shutdown();

    error NotUnlocked();
    error StakerNotDeployed();
    error AlreadyShutdown();

    /**
     * @notice Locks the caller's TLX tokens.
     * @param amount The amount of TLX tokens to lock.
     */
    function lock(uint256 amount) external;

    /**
     * @notice Migrates the caller's TLX tokens to the new staker.
     */
    function migrate() external;

    /**
     * @notice Migrates the caller's TLX tokens to the new staker for the given account.
     * @param receiver The account to migrate the TLX tokens to.
     */
    function migrateFor(address receiver) external;

    /**
     * @notice Shuts down the locker, allowing locked TLX tokens to be withdrawn and transfering
     * the rest of the rewards to the treasury.
     */
    function shutdown() external;

    /**
     * @notice Returns whether the locker has been shut down.
     */
    function isShutdown() external view returns (bool);

    /**
     * @notice Returns the duration of the lock.
     * @return lockTime The duration of the lock.
     */
    function lockTime() external view returns (uint256 lockTime);

    /**
     * @notice Returns the total amount of rewards donated.
     * @return totalRewards The total amount of rewards donated.
     */
    function totalRewards() external view returns (uint256 totalRewards);

    /**
     * @notice Returns the time when the rewards started streaming.
     * @return rewardsStartTime The time when the rewards started streaming.
     */
    function rewardsStartTime()
        external
        view
        returns (uint256 rewardsStartTime);

    /**
     * @notice Returns the time at which the given account's TLX tokens are unlocked.
     * @param account The account to return the unlock time for.
     * @return time The time at which the given account's TLX tokens are unlocked.
     */
    function unlockTime(address account) external view returns (uint256 time);

    /**
     * @notice Returns the amount of TLX that has been streamed as rewards so far.
     * @return amountStreamed The amount of TLX that has been streamed as rewards so far.
     */
    function amountStreamed() external view returns (uint256 amountStreamed);
}
