// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";

import {Config} from "../src/libraries/Config.sol";
import {AddressKeys} from "../src/libraries/AddressKeys.sol";

import {IAirdrop} from "../src/interfaces/IAirdrop.sol";

contract AirdropTest is IntegrationTest {
    address public constant CLAIMER =
        0x1Ccf968217dCD3FaD42029115Dab5d329d9F32ce;
    uint256 public constant CLAIMER_AMOUNT = 2830e18;

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
        proof[
            0
        ] = 0x682ae8df89d55f815f623ee1171fd1c3eb016ac245076d9b828d4dac9476ddae;
        proof[
            1
        ] = 0x94b6b4133af42fcdfec3a79d5a1cddc97eaf781401117de0e3b8fb2f60652254;
        proof[
            2
        ] = 0xf601ba5e944f99f94d04528f080825d22a70550cd31f56c0877bdd51a80359c6;
        proof[
            3
        ] = 0xaa95459eecc956a82ef909045ba480ab8d10e59c87973cc88878e64971ef9d1d;
        proof[
            4
        ] = 0xbccce1375747268e9be58f73a30acd5216adf6bb0243629c71b71fcf4f4c6536;
        proof[
            5
        ] = 0x98868fa621a12b4ba6f0359d46f47416b23ba6e47357ec63260cd3652150e123;
        proof[
            6
        ] = 0x4d0f01ab1c5524bec131efa0dc372a0b6431d666e58878b6ff822125c37ed5ca;
        proof[
            7
        ] = 0xebdd3d6fdd1e75fc9391c2312d1e13a9293ed35e4d686a1c5bed14461348ce9e;
        proof[
            8
        ] = 0x4f9756ff6c824b4cb31acebad1ed74e804a7ed51af19e15eecce81fd909fabde;
        proof[
            9
        ] = 0x94f37fecbfd6e3470f26b24453778c7e12e078b58e09bf1907e1c8a24e6fa720;
    }
}
