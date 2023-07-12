// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {TlxMaxSupply} from "../src/libraries/TlxMaxSupply.sol";
import {AddressKeys} from "../src/libraries/AddressKeys.sol";

import {IAirdrop} from "../src/interfaces/IAirdrop.sol";

contract AirdropTest is IntegrationTest {
    bytes32 public constant MERKLE_ROOT =
        bytes32(
            0x2918c390ed100321540bb32423c36c8c0586225e6430e5f33d2ddccf4d18f33f
        );
    bytes32 public constant BOB_PROOF =
        bytes32(
            0x0193a26196144ade3707bf69bc3877126358fe50d9ab922fe7debf57f54633d5
        );

    function setUp() public {
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
        airdrop.claim(1, 1, new bytes32[](0));
    }

    function testClaim() public {
        bytes32[] memory merklePr = new bytes32[](1);
        merklePr[0] = BOB_PROOF;
        vm.prank(bob);
        airdrop.claim(0, 321, merklePr);
        assertEq(airdrop.totalClaimed(), 321e18, "totalClaimed");
        assertEq(airdrop.hasClaimed(alice), false, "hasClaimed(alice)");
        assertEq(airdrop.hasClaimed(bob), true, "hasClaimed(bob)");
        assertEq(tlx.balanceOf(bob), 321e18, "balanceOf(bob)");
        assertEq(tlx.balanceOf(alice), 0, "balanceOf(alice)");
        assertEq(tlx.balanceOf(treasury), 0, "balanceOf(treasury)");
    }

    function testRevertsWhenAlreadyClaimed() public {
        bytes32[] memory merklePr = new bytes32[](1);
        merklePr[0] = BOB_PROOF;
        vm.startPrank(bob);
        airdrop.claim(0, 321, merklePr);
        vm.expectRevert(IAirdrop.AlreadyClaimed.selector);
        airdrop.claim(0, 321, merklePr);
    }

    function testRevertsForInvalidProof() public {
        bytes32[] memory merklePr = new bytes32[](1);
        merklePr[0] = BOB_PROOF;
        vm.expectRevert(IAirdrop.InvalidMerkleProof.selector);
        airdrop.claim(0, 321, merklePr);
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

    function testMintUnclaimedRevertsForInvalidTreasury() public {
        addressProvider.updateAddress(AddressKeys.TREASURY, address(0));
        skip(200 days);
        vm.expectRevert(IAirdrop.InvalidTreasury.selector);
        airdrop.mintUnclaimed();
    }

    function testMintUnclaimed() public {
        skip(200 days);
        airdrop.mintUnclaimed();
        assertEq(
            tlx.balanceOf(treasury),
            TlxMaxSupply.AIRDRIP_MAX_SUPPLY,
            "balanceOf(treasury)"
        );
    }
}
