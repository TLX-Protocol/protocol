// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IRewardsStreaming {
    event Claimed(address indexed account, uint256 amount);
    event DonatedRewards(address indexed account, uint256 amount);

    error ZeroAmount();
    error InsufficientBalance();

    /**
     * @notice Claims the caller's rewards.
     */
    function claim() external;

    /**
     * @notice Donates an amount of the reward token to the staker.
     */
    function donateRewards(uint256 amount) external;

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
     * @notice Returns the amount of reward tokens claimable for the given account.
     * @param account The account to return the claimable reward tokens for.
     * @return amount The amount of reward tokens claimable for the given account.
     */
    function claimable(address account) external view returns (uint256 amount);

    /**
     * @notice Returns the number of decimals the Staker's token uses.
     * @return decimals The number of decimals the Staker's token uses.
     */
    function decimals() external view returns (uint8 decimals);

    /**
     * @notice Returns the address of the reward token.
     * @return rewardToken The address of the reward token.
     */
    function rewardToken() external view returns (address rewardToken);
}
