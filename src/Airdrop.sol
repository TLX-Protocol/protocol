// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

import {IAirdrop} from "./interfaces/IAirdrop.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract Airdrop is IAirdrop, Ownable {
    IAddressProvider internal immutable _addressProvider;
    uint256 internal immutable _airdropAmount;

    bytes32 public override merkleRoot;
    mapping(address => bool) public override hasClaimed;
    uint256 public override deadline;
    uint256 public override totalClaimed;

    constructor(
        address addressProvider_,
        bytes32 merkleRoot_,
        uint256 deadline_,
        uint256 airdropAmount_
    ) {
        _addressProvider = IAddressProvider(addressProvider_);
        merkleRoot = merkleRoot_;
        deadline = deadline_;
        _airdropAmount = airdropAmount_;
    }

    function claim(
        uint256 amount_,
        bytes32[] calldata merkleProof_
    ) external override {
        // Checking claim is valid
        address account_ = msg.sender;
        if (block.timestamp > deadline) revert ClaimPeriodOver();
        if (hasClaimed[account_]) revert AlreadyClaimed();
        if (!_isValid(account_, amount_, merkleProof_)) {
            revert InvalidMerkleProof();
        }
        uint256 totalClaimed_ = totalClaimed;
        bool completed_ = totalClaimed_ == _airdropAmount;
        if (completed_) revert AirdropCompleted();

        // Minting tokens
        if (totalClaimed_ + amount_ > _airdropAmount) {
            amount_ = _airdropAmount - totalClaimed_;
        }

        // Updating state
        hasClaimed[account_] = true;
        totalClaimed += amount_;
        _addressProvider.tlx().transfer(account_, amount_);
        emit Claimed(account_, amount_);
    }

    function updateMerkleRoot(bytes32 merkleRoot_) external override onlyOwner {
        merkleRoot = merkleRoot_;
        emit MerkleRootUpdated(merkleRoot_);
    }

    function mintUnclaimed() external override onlyOwner {
        if (block.timestamp <= deadline) revert ClaimStillOngoing();
        address treasury_ = _addressProvider.treasury();
        if (treasury_ == address(0)) revert InvalidTreasury();
        uint256 unclaimed_ = _airdropAmount - totalClaimed;
        if (unclaimed_ == 0) revert EverythingClaimed();
        _addressProvider.tlx().transfer(treasury_, unclaimed_);
        emit UnclaimedMinted(unclaimed_);
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
