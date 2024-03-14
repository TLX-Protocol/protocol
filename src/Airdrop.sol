// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

import {TlxOwnable} from "./utils/TlxOwnable.sol";

import {IAirdrop} from "./interfaces/IAirdrop.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract Airdrop is IAirdrop, TlxOwnable {
    IAddressProvider internal immutable _addressProvider;
    uint256 internal immutable _airdropAmount;

    /// @inheritdoc IAirdrop
    bytes32 public override merkleRoot;
    /// @inheritdoc IAirdrop
    mapping(address => bool) public override hasClaimed;
    /// @inheritdoc IAirdrop
    uint256 public immutable override deadline;
    /// @inheritdoc IAirdrop
    uint256 public override totalClaimed;

    constructor(
        address addressProvider_,
        bytes32 merkleRoot_,
        uint256 deadline_,
        uint256 airdropAmount_
    ) TlxOwnable(addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
        merkleRoot = merkleRoot_;
        deadline = deadline_;
        _airdropAmount = airdropAmount_;
    }

    /// @inheritdoc IAirdrop
    function claim(
        uint256 amount_,
        bytes32[] calldata merkleProof_
    ) external override {
        // Checking claim is valid
        if (block.timestamp > deadline) revert ClaimPeriodOver();
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        if (!_isValid(msg.sender, amount_, merkleProof_)) {
            revert InvalidMerkleProof();
        }
        uint256 totalClaimed_ = totalClaimed;
        uint256 airdropAmount_ = _airdropAmount;
        bool completed_ = totalClaimed_ == airdropAmount_;
        if (completed_) revert AirdropCompleted();

        // Minting tokens
        if (totalClaimed_ + amount_ > airdropAmount_) {
            amount_ = airdropAmount_ - totalClaimed_;
        }

        // Updating state
        hasClaimed[msg.sender] = true;
        totalClaimed += amount_;
        _addressProvider.tlx().transfer(msg.sender, amount_);
        emit Claimed(msg.sender, amount_);
    }

    /// @inheritdoc IAirdrop
    function updateMerkleRoot(bytes32 merkleRoot_) external override onlyOwner {
        merkleRoot = merkleRoot_;
        emit MerkleRootUpdated(merkleRoot_);
    }

    /// @inheritdoc IAirdrop
    function recoverUnclaimed() external override onlyOwner {
        if (block.timestamp <= deadline) revert ClaimStillOngoing();
        IAddressProvider addressProvider_ = _addressProvider;
        address treasury_ = addressProvider_.treasury();
        uint256 unclaimed_ = _airdropAmount - totalClaimed;
        if (unclaimed_ == 0) revert EverythingClaimed();
        addressProvider_.tlx().transfer(treasury_, unclaimed_);
        emit UnclaimedRecovered(unclaimed_);
    }

    function _isValid(
        address account_,
        uint256 amount_,
        bytes32[] calldata merkleProof_
    ) internal view returns (bool) {
        bytes32 node_ = keccak256(abi.encodePacked(account_, amount_));
        return MerkleProof.verify(merkleProof_, merkleRoot, node_);
    }
}
