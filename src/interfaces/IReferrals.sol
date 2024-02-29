// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IReferrals {
    event Registered(address indexed user, bytes32 code);
    event SetReferral(address indexed user, bytes32 code);
    event RebateSet(uint256 rebate);
    event EarningsSet(uint256 earnings);
    event EarningsTaken(address indexed user, uint256 amount);
    event EarningsClaimed(address indexed user, uint256 amount);

    error AlreadyRegistered();
    error InvalidCode();
    error CodeTaken();
    error AlreadyOpen();
    error NotLeveragedToken();
    error NotChanged();
    error InvalidAmount();

    /**
     * @notice Takes the referral earnings from the given fees for the given user.
     * @param fees The fees to take the earnings from.
     * @param user The user to take the earnings for.
     * @return earnings The earnings taken.
     */
    function takeEarnings(
        uint256 fees,
        address user
    ) external returns (uint256 earnings);

    /**
     * @notice Claims the referral earnings for the sender.
     * @return earnings The earnings claimed.
     */
    function claimEarnings() external returns (uint256 earnings);

    /**
     * @notice Registers the given code for the sender.
     * @param code The code to register.
     */
    function register(address referrer, bytes32 code) external;

    /**
     * @notice Sets the referral code for the sender.
     * @dev Reverts if the user has already set a code.
     * @param code The code to use.
     */
    function setReferral(bytes32 code) external;

    /**
     * @notice Sets the rebate percent.
     * @dev Can only be called by the owner.
     * @param rebatePercent The rebate percent to set.
     */
    function setRebatePercent(uint256 rebatePercent) external;

    /**
     * @notice Sets the earnings percent.
     * @dev Can only be called by the owner.
     * @param earningsPercent The earnings percent to set.
     */
    function setEarningsPercent(uint256 earningsPercent) external;

    /**
     * @notice Returns the reabate for the given code.
     * @param code The code to get the rebate for.
     * @return rebate The rebate for the given code.
     */
    function codeRebate(bytes32 code) external view returns (uint256 rebate);

    /**
     * @notice Returns the rebate for the given user.
     * @param user The user to get the rebate for.
     * @return rebate The rebate for the given user.
     */
    function userRebate(address user) external view returns (uint256 rebate);

    /**
     * @notice Returns the referrer for the given code.
     * @param code The code to get the referrer for.
     * @return referrer The referrer for the given code.
     */
    function referrer(bytes32 code) external view returns (address referrer);

    /**
     * @notice Returns the code for the given referrer
     * @param referrer The referrer to get the code for.
     * @return code The code for the given referrer.
     */
    function code(address referrer) external view returns (bytes32 code);

    /**
     * @notice Returns the code for the given user.
     * @param user The user to get the code for.
     * @return code The code for the given user.
     */
    function referral(address user) external view returns (bytes32 code);

    /**
     * @notice Returns the earnings for the given referrer.
     * @param referrer The referrer to get the earnings for.
     * @return earned The earnings for the given referrer.
     */
    function earned(address referrer) external view returns (uint256 earned);

    /**
     * @notice Returns the rebate percent.
     * @dev As a percent of fees, e.g 10% as 0.1e18.
     * @return rebatePercent The rebate percent.
     */
    function rebatePercent() external view returns (uint256 rebatePercent);

    /**
     * @notice Returns the earnings percent.
     * @dev As a percent of fees, e.g 10% as 0.1e18.
     * @return earningsPercent The earnings percent.
     */
    function earningsPercent() external view returns (uint256 earningsPercent);
}
