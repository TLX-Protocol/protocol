// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Config} from "../src/libraries/Config.sol";
import {AddressKeys} from "../src/libraries/AddressKeys.sol";

import {IAirdrop} from "../src/interfaces/IAirdrop.sol";

contract AirdropTest is IntegrationTest {
    bytes32 public constant MERKLE_ROOT =
        bytes32(
            0x468a9099f57f82cbafabb8f3f00efa98e5f6d0edd1a937b2aaec7293e6b9156f
        );
    bytes32 public constant BOB_PROOF =
        bytes32(
            0x805205e4cf7a5e483078d8f80da53ff73f9830b97b11bfcffe69d5423490c794
        );

    function setUp() public override {
        super.setUp();
        airdrop.updateMerkleRoot(MERKLE_ROOT);
    }

    function testInit() public {
        assertEq(airdrop.merkleRoot(), MERKLE_ROOT);
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
        bytes32[] memory merklePr = new bytes32[](1);
        merklePr[0] = BOB_PROOF;
        vm.prank(bob);
        airdrop.claim(321e18, merklePr);
        assertEq(airdrop.totalClaimed(), 321e18, "totalClaimed");
        assertEq(airdrop.hasClaimed(alice), false, "hasClaimed(alice)");
        assertEq(airdrop.hasClaimed(bob), true, "hasClaimed(bob)");
        assertEq(tlx.balanceOf(bob), 321e18, "balanceOf(bob)");
        assertEq(tlx.balanceOf(alice), 0, "balanceOf(alice)");
    }

    function testRevertsWhenAlreadyClaimed() public {
        bytes32[] memory merklePr = new bytes32[](1);
        merklePr[0] = BOB_PROOF;
        vm.startPrank(bob);
        airdrop.claim(321e18, merklePr);
        vm.expectRevert(IAirdrop.AlreadyClaimed.selector);
        airdrop.claim(321e18, merklePr);
    }

    function testRevertsForInvalidProof() public {
        bytes32[] memory merklePr = new bytes32[](1);
        merklePr[0] = BOB_PROOF;
        vm.expectRevert(IAirdrop.InvalidMerkleProof.selector);
        airdrop.claim(321e18, merklePr);
    }

    function testUpdateMerkleRootRevertsForNonOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        airdrop.updateMerkleRoot(MERKLE_ROOT);
    }

    function testMintUnclaimedFailsForNonOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        airdrop.mintUnclaimed();
    }

    function testMintUnclaimedFailsWhenStillOngoing() public {
        vm.expectRevert(IAirdrop.ClaimStillOngoing.selector);
        airdrop.mintUnclaimed();
    }

    function testMintUnclaimed() public {
        skip(200 days);
        airdrop.mintUnclaimed();
        assertEq(
            tlx.balanceOf(treasury),
            Config.DIRECT_AIRDROP_AMOUNT,
            "balanceOf(treasury)"
        );
    }
}
