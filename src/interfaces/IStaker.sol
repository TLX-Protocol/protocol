// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IRewardsStreaming} from "./IRewardsStreaming.sol";
import {Unstakes} from "../libraries/Unstakes.sol";

interface IStaker is IRewardsStreaming {
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

    error NotUnstaked();
    error ClaimingNotEnabled();
    error ClaimingAlreadyEnabled();
    error ZeroBalance();

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
     * @notice Returns the symbol of the Staker.
     * @return symbol The symbol of the Staker.
     */
    function symbol() external view returns (string memory symbol);

    /**
     * @notice Returns the name of the Staker.
     * @return name The name of the Staker.
     */
    function name() external view returns (string memory name);

    /**
     * @notice Returns the total amount of TLX tokens prepared for unstaking.
     * @return amount The total amount of TLX tokens prepared for unstaking.
     */
    function totalPrepared() external view returns (uint256 amount);

    /**
     * @notice Returns all the queued unstakes for the given account.
     * @param account The account to return the unstakes for.
     * @return unstakes All the queued unstakes for the given account.
     */
    function listQueuedUnstakes(
        address account
    ) external view returns (Unstakes.UserUnstakeData[] memory unstakes);

    /**
     * @notice Returns the delay the user must wait when unstakeing.
     * @return delay The delay the user must wait when unstakeing.
     */
    function unstakeDelay() external view returns (uint256 delay);
}
