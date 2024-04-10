// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Config} from "../src/libraries/Config.sol";
import {AddressKeys} from "../src/libraries/AddressKeys.sol";

import {IAirdrop} from "../src/interfaces/IAirdrop.sol";

contract AirdropTest is IntegrationTest {
    address public constant CLAIMER = 0x1ba6B82641C77aB1Fc7Bc734C5C3628199A8967D;
    uint256 public constant CLAIMER_AMOUNT = 3158e18;

    function setUp() public override {
        super.setUp();
        airdrop.updateMerkleRoot(Config.MERKLE_ROOT);
    }

    function testInit() public {
        assertEq(airdrop.merkleRoot(), Config.MERKLE_ROOT);
        assertApproxEqAbs(airdrop.deadline(), block.timestamp + 180 days, 100);
        assertEq(airdrop.totalClaimed(), 0);
        assertEq(airdrop.hasClaimed(alice), false);
        assertEq(airdrop.hasClaimed(bob), false);
        assertEq(tlx.balanceOf(alice), 0);
        assertEq(tlx.balanceOf(bob), 0);
    }

    function testClaimingAfterDeadlineReverts() public {
        skip(200 days);
        vm.expectRevert(IAirdrop.ClaimPeriodOver.selector);
        airdrop.claim(1, new bytes32[](0));
    }

    function testClaim() public {
        bytes32[] memory proof = _getProof();
        vm.prank(CLAIMER);
        airdrop.claim(CLAIMER_AMOUNT, proof);
        assertEq(airdrop.totalClaimed(), CLAIMER_AMOUNT, "totalClaimed");
        assertEq(airdrop.hasClaimed(alice), false, "hasClaimed(alice)");
        assertEq(airdrop.hasClaimed(CLAIMER), true, "hasClaimed(CLAIMER)");
        assertEq(tlx.balanceOf(CLAIMER), CLAIMER_AMOUNT, "balanceOf(CLAIMER)");
        assertEq(tlx.balanceOf(alice), 0, "balanceOf(alice)");
    }

    function testRevertsWhenAlreadyClaimed() public {
        bytes32[] memory proof = _getProof();
        vm.startPrank(CLAIMER);
        airdrop.claim(CLAIMER_AMOUNT, proof);
        vm.expectRevert(IAirdrop.AlreadyClaimed.selector);
        airdrop.claim(CLAIMER_AMOUNT, proof);
    }

    function testRevertsForInvalidProof() public {
        bytes32[] memory proof = _getProof();
        vm.expectRevert(IAirdrop.InvalidMerkleProof.selector);
        airdrop.claim(321e18, proof);
    }

    function testUpdateMerkleRootRevertsForNonOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        airdrop.updateMerkleRoot(Config.MERKLE_ROOT);
    }

    function testRecoverUnclaimedFailsForNonOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        airdrop.recoverUnclaimed();
    }

    function testRecoverUnclaimedFailsWhenStillOngoing() public {
        vm.expectRevert(IAirdrop.ClaimStillOngoing.selector);
        airdrop.recoverUnclaimed();
    }

    function testRecoverUnclaimed() public {
        skip(200 days);
        airdrop.recoverUnclaimed();
        assertEq(
            tlx.balanceOf(treasury),
            Config.DIRECT_AIRDROP_AMOUNT,
            "balanceOf(treasury)"
        );
    }

    function _getProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](10);
        proof[0] = 0x5a9520dc43800425ce0aa6bf1e96aa01d2a2912b913ff3aa795cfd6b3ba5eaea;
        proof[1] = 0x8424ff9f7120fe2b5a1fa99886a05bd82a7213d79ac674b589bff5d6ce0e0c64;
        proof[2] = 0x922bd2311af9ebfa34e7d0a4a5c14089c9c7153b9d554c09f75d16f39a94706a;
        proof[3] = 0x68d293a9f1400e8865792e4b37f37b64fd8d99a3bb2d949ecc36b9c2d805eceb;
        proof[4] = 0xd3a52c552d5bb2aab873e08cc8ea6b2f62a109e5fb2e0991b0b7315162b60bff;
        proof[5] = 0x7fc32cb663eaefbeb4dbf3f2a59d8adcc2bebdbb1d8009b910cf39d231b1bfdb;
        proof[6] = 0x667e9944dae4145416c81edd7a1499fffc7a48d001e46a445432bac9126c9635;
        proof[7] = 0xba8bc0481816d02c5aa235a2f89f81b051204217dd11cbe988eccfa098f6aba8;
        proof[8] = 0x0d6abf0024ead8712492665b45c64aeb0b2d5629720d82cc678613639698e205;
        proof[9] = 0x6c5acfab3f8db9cf4e6c333991ceb6170a0536f30961eec9786fdd652f17d03f;
    }
}
