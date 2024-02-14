// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IBaseStaker {
    event Staked(
        address indexed accountFrom,
        address indexed accountTo,
        uint256 amount
    );
    event PreparedUnstake(address indexed account);
    event Unstaked(
        address indexed accountFrom,
        address indexed accountTo,
        uint256 amount
    );
    event Restaked(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount);
    event DonatedRewards(address indexed account, uint256 amount);

    error ZeroAmount();
    error ZeroBalance();
    error InsufficientBalance();
    error AlreadyPreparedUnstake();
    error NoUnstakePrepared();
    error NotUnstaked();
    error UnstakePrepared();
    error ClaimingNotEnabled();
    error ClaimingAlreadyEnabled();

    /**
     * @notice Stakes TLX tokens for the caller.
     * @param amount The amount of TLX tokens to stake.
     */
    function stake(uint256 amount) external;

    /**
     * @notice Stakes TLX tokens for the caller for the account.
     * @param amount The amount of TLX tokens to stake.
     * @param account The account to stake the TLX tokens to.
     */
    function stakeFor(uint256 amount, address account) external;

    /**
     * @notice Prepares the caller's staked TLX tokens for unstaking.
     * @return id The ID of the withdrawal to be unstaked.
     */
    function prepareUnstake(uint256 amount) external returns (uint256 id);

    /**
     * @notice Unstakes the caller's TLX tokens.
     * @param withdrawalId The ID of the withdrawal to unstake.
     */
    function unstake(uint256 withdrawalId) external;

    /**
     * @notice Restakes the caller's prepared TLX tokens.
     * @param withdrawalId The ID of the withdrawal to restake.
     */
    function restake(uint256 withdrawalId) external;

    /**
     * @notice Unstakes the caller's TLX tokens for the given account.
     * @param account The account to send the TLX tokens to.
     * @param withdrawalId The ID of the withdrawal to unstake.
     */
    function unstakeFor(address account, uint256 withdrawalId) external;

    /**
     * @notice Claims the caller's rewards.
     */
    function claim() external;

    /**
     * @notice Donates an amount of the reward token to the staker.
     */
    function donateRewards(uint256 amount) external;

    /**
     * @notice Enables claiming for stakers.
     * @dev This can only be called by the owner.
     */
    function enableClaiming() external;

    /**
     * @notice Returns if claiming is enabled for stakers.
     * @return claimingEnabled Whether claiming is enabled for stakers.
     */
    function claimingEnabled() external view returns (bool claimingEnabled);

    /**
     * @notice Returns the amount of TLX tokens staked for the given account.
     * @param account The account to return the staked TLX tokens for.
     * @return amount The amount of TLX tokens staked for the given account.
     */
    function balanceOf(address account) external view returns (uint256 amount);

    /**
     * @notice Returns the amount of TLX tokens staked for the given account
     * minus the amount queued for withdrawal.
     * @param account The account to return the staked TLX tokens for.
     * @return amount The amount of TLX tokens staked and not queued for the given account.
     */
    function activeBalanceOf(
        address account
    ) external view returns (uint256 amount);

    /**
     * @notice Returns the total amount of TLX tokens staked.
     * @return amount The total amount of TLX tokens staked.
     */
    function totalStaked() external view returns (uint256 amount);

    /**
     * @notice Returns the total amount of TLX tokens prepared for unstakeing.
     * @return amount The total amount of TLX tokens prepared for unstakeing.
     */
    function totalPrepared() external view returns (uint256 amount);

    /**
     * @notice Returns the amount of reward tokens claimable for the given account.
     * @param account The account to return the claimable reward tokens for.
     * @return amount The amount of reward tokens claimable for the given account.
     */
    function claimable(address account) external view returns (uint256 amount);

    /**
     * @notice Returns the timestamp for when the given account's TLX tokens are unstaked.
     * @dev Returns 0 if the account's TLX tokens are not prepared for unstakeing.
     * @param account The account to return the unstake time for.
     * @param withdrawalId The ID of the withdrawal to return the unstake time for.
     * @return time The timestamp for when the given account's TLX tokens are unstaked.
     */
    function unstakeTime(
        address account,
        uint256 withdrawalId
    ) external view returns (uint256 time);

    /**
     * @notice Returns whether the given account's TLX tokens are unstaked.
     * @param account The account to return whether the TLX tokens are unstaked for.
     * @param withdrawalId The ID of the withdrawal to check.
     * @return unstaked Whether the given account's TLX tokens are unstaked.
     */
    function isUnstaked(
        address account,
        uint256 withdrawalId
    ) external view returns (bool);

    /**
     * @notice Returns the number of decimals the Staker's token uses.
     * @return decimals The number of decimals the Staker's token uses.
     */
    function decimals() external view returns (uint8 decimals);

    /**
     * @notice Returns the delay the user must wait when unstakeing.
     * @return delay The delay the user must wait when unstakeing.
     */
    function unstakeDelay() external view returns (uint256 delay);

    /**
     * @notice Returns the address of the reward token.
     * @return rewardToken The address of the reward token.
     */
    function rewardToken() external view returns (address rewardToken);
}
