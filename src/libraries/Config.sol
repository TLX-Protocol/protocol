// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Tokens} from "./Tokens.sol";

library Config {
    uint256 public constant AIRDRIP_AMOUNT = 1_000_000e18;
    uint256 public constant BONDING_AMOUNT = 7_500_000e18;
    uint256 public constant TREASURY_AMOUNT = 500_000e18;
    uint256 public constant VESTING_AMOUNT = 1_000_000e18;
    uint256 public constant AIRDROP_CLAIM_PERIOD = 180 days;
    uint256 public constant LOCKER_UNLOCK_DELAY = 7 days;
    address public constant REWARD_TOKEN = Tokens.USDC;
}
