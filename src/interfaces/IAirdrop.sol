// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IAirdrop {
    event MerkleRootUpdated(bytes32 merkleRoot);
    event Claimed(address indexed account, uint256 amount);
    event UnclaimedRecovered(uint256 amount);

    error ClaimPeriodOver();
    error InvalidMerkleProof();
    error AlreadyClaimed();
    error AirdropCompleted();
    error EverythingClaimed();
    error ClaimStillOngoing();

    /**
     * @notice Claim tokens from the airdrop.
     * @param amount The amount of tokens to claim.
     * @param merkleProof The merkle proof for the account.
     */
    function claim(uint256 amount, bytes32[] calldata merkleProof) external;

    /**
     * @notice Update the merkle root for the airdrop.
     * @param merkleRoot_ The new merkle root.
     */
    function updateMerkleRoot(bytes32 merkleRoot_) external;

    /**
     * @notice Recover unclaimed tokens to the treasury.
     */
    function recoverUnclaimed() external;

    /**
     * @notice Returns the merkle root for the airdrop.
     * @return merkleRoot The merkle root for the airdrop.
     */
    function merkleRoot() external view returns (bytes32 merkleRoot);

    /**
     * @notice Returns if the `account` has claimed their airdrop.
     * @param account The account to check.
     * @return hasClaimed If the `account` has claimed their airdrop.
     */
    function hasClaimed(
        address account
    ) external view returns (bool hasClaimed);

    /**
     * @notice Returns the deadline for the airdrop.
     * @return deadline The deadline for the airdrop.
     */
    function deadline() external view returns (uint256 deadline);

    /**
     * @notice Returns the total amount of tokens claimed.
     * @return totalClaimed The total amount of tokens claimed.
     */
    function totalClaimed() external view returns (uint256 totalClaimed);
}
