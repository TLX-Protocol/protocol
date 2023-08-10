// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IReferrals {
    event Registered(address indexed user, bytes32 code);
    event UpdatedReferral(address indexed user, bytes32 code);
    event PartnerSet(address indexed referrer, bool isPartner);
    event ReferralDiscountSet(uint256 discount);
    event ReferralEarningsSet(uint256 earnings);
    event PartnerDiscountSet(uint256 discount);
    event PartnerEarningsSet(uint256 earnings);

    error AlreadyRegistered();
    error InvalidCode();
    error CodeTaken();
    error SameCode();
    error AlreadyOpen();
    error NotPositionManager();
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
    function register(bytes32 code) external;

    /**
     * @notice Updates the referral code for the sender.
     * @param code The code to update to.
     */
    function updateReferral(bytes32 code) external;

    /**
     * @notice Updates the referral code for the given user.
     * @dev Can only be called by the position manager.
     * @param user The user to update the code for.
     * @param code The code to update to.
     */
    function updateReferralFor(address user, bytes32 code) external;

    /**
     * @notice Sets the given referrer as a partner or not.
     * @dev Can only be called by the owner.
     * @param referrer The referrer to set as a partner.
     * @param isPartner Whether or not the referrer is a partner.
     */
    function setPartner(address referrer, bool isPartner) external;

    /**
     * @notice Sets the referral discount.
     * @dev Can only be called by the owner.
     * @param discount The discount to set.
     */
    function setReferralDiscount(uint256 discount) external;

    /**
     * @notice Sets the referral earnings.
     * @dev Can only be called by the owner.
     * @param earnings The earnings to set.
     */
    function setReferralEarnings(uint256 earnings) external;

    /**
     * @notice Sets the partner discount.
     * @dev Can only be called by the owner.
     * @param discount The discount to set.
     */
    function setPartnerDiscount(uint256 discount) external;

    /**
     * @notice Sets the partner earnings.
     * @dev Can only be called by the owner.
     * @param earnings The earnings to set.
     */
    function setPartnerEarnings(uint256 earnings) external;

    /**
     * @notice Returns the discount for the given code.
     * @param code The code to get the discount for.
     * @return discount The discount for the given code.
     */
    function discount(bytes32 code) external view returns (uint256 discount);

    /**
     * @notice Returns the discount for the given user.
     * @param user The user to get the discount for.
     * @return discount The discount for the given user.
     */
    function discount(address user) external view returns (uint256 discount);

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
     * @notice Returns whether or not the given referrer is a partner.
     * @param referrer The referrer to check.
     * @return isPartner Whether or not the given referrer is a partner.
     */
    function isPartner(address referrer) external view returns (bool isPartner);

    /**
     * @notice Returns the earnings for the given referrer.
     * @param referrer The referrer to get the earnings for.
     * @return earned The earnings for the given referrer.
     */
    function earned(address referrer) external view returns (uint256 earned);

    /**
     * @notice Returns the referral discount.
     * @dev As a percent of fees, e.g 10% as 0.1e18.
     * @return discount The referral discount.
     */
    function referralDiscount() external view returns (uint256 discount);

    /**
     * @notice Returns the referral earnings.
     * @dev As a percent of fees, e.g 10% as 0.1e18.
     * @return earnings The referral earnings.
     */
    function referralEarnings() external view returns (uint256 earnings);

    /**
     * @notice Returns the partner discount.
     * @dev As a percent of fees, e.g 10% as 0.1e18.
     * @return discount The partner discount.
     */
    function partnerDiscount() external view returns (uint256 discount);

    /**
     * @notice Returns the partner earnings.
     * @dev As a percent of fees, e.g 10% as 0.1e18.
     * @return earnings The partner earnings.
     */
    function partnerEarnings() external view returns (uint256 earnings);
}
