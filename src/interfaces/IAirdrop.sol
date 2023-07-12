// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IAirdrop {
    event MerkleRootUpdated(bytes32 merkleRoot);
    event Claimed(address indexed account, uint256 amount);
    event UnclaimedMinted(uint256 amount);

    error ClaimPeriodOver();
    error InvalidMerkleProof();
    error AlreadyClaimed();
    error AirdropCompleted();
    error InvalidTreasury();
    error EverythingClaimed();
    error ClaimStillOngoing();

    function claim(
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    function updateMerkleRoot(bytes32 merkleRoot_) external;

    function mintUnclaimed() external;

    function merkleRoot() external view returns (bytes32);

    function hasClaimed(address account) external view returns (bool);

    function deadline() external view returns (uint256);

    function totalClaimed() external view returns (uint256);
}
