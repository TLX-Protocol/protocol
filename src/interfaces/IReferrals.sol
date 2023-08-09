// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IReferrals {
    error AlreadyRegistered();
    error InvalidCode();
    error CodeTaken();
    error SameCode();
    error AlreadyOpen();
    error NotPositionManager();
    error NotChanged();
    error InvalidAmount();

    event Registered(address indexed user, bytes32 code);
    event UpdatedReferral(address indexed user, bytes32 code);
    event PartnerSet(address indexed referrer, bool isPartner);
    event ReferralDiscountSet(uint256 discount);
    event ReferralEarningsSet(uint256 earnings);
    event PartnerDiscountSet(uint256 discount);
    event PartnerEarningsSet(uint256 earnings);

    function register(bytes32 code) external;

    function updateReferral(bytes32 code) external;

    function updateCodeFor(bytes32 code, address user) external;

    function setPartner(address referrer, bool isPartner) external;

    function setReferralDiscount(uint256 discount) external;

    function setReferralEarnings(uint256 earnings) external;

    function setPartnerDiscount(uint256 discount) external;

    function setPartnerEarnings(uint256 earnings) external;

    function discount(bytes32 code) external view returns (uint256);

    function discount(address user) external view returns (uint256);

    function referrer(bytes32 code) external view returns (address);

    function code(address referrer) external view returns (bytes32);

    function referral(address user) external view returns (bytes32);

    function isPartner(address referrer) external view returns (bool);

    function referralDiscount() external view returns (uint256);

    function referralEarnings() external view returns (uint256);

    function partnerDiscount() external view returns (uint256);

    function partnerEarnings() external view returns (uint256);
}
