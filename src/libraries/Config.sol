// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Tokens} from "./Tokens.sol";

library Config {
    // Addresses
    address public constant BASE_ASSET = Tokens.SUSD; // sUSD
    address public constant BINANCE =
        0xacD03D601e5bB1B275Bb94076fF46ED9D753435A; // Used for testing scripts
    address public constant AMM_DISTRIBUTOR =
        0x9d27E96B3564e51422C1f0592f42b3934f2bd056; // AMM distributor (multisig)
    address public constant DAO_TREASURY =
        0x6E28337E25717553E7f7F3e89Ad19F6cd01f3b2c;
    address public constant COMPANY_MULTISIG =
        0x9B59228F2ae19f9C7B50e4d4755F1C85cad78C90;
    address public constant POL = address(1); // Where the bonding tokens are sent to
    address public constant REBALANCE_FEE_RECEIVER =
        0xf6A741259da6ee0d1A863bd847b12A6c2943Ea57; // Receiver of rebalance fees
    address public constant CHAINLINK_AUTOMATION_FORWARDER_ADDRESS = address(7); // The forwarder address for Chainlink automation
    address public constant TEAM_MULTISIG =
        0x4185075BF51A76DB3f6501FBDA5a6B9e77f7bbFd; // Set as the owner of the ProxyOwner contract

    // Strings
    string public constant TOKEN_NAME = "TLX DAO Token"; // TLX DAO Token
    string public constant TOKEN_SYMBOL = "TLX"; // TLX

    // Values
    uint256 public constant TOTAL_SUPPLY = 100_000_000e18; // 100 million TLX
    uint256 public constant AMM_AMOUNT = (TOTAL_SUPPLY * 10) / 100; // 10%
    uint256 public constant DIRECT_AIRDROP_AMOUNT = (TOTAL_SUPPLY * 6) / 100; // 6% (goes to airdrop contract directly)
    uint256 public constant STREAMED_AIRDROP_AMOUNT = (TOTAL_SUPPLY * 4) / 100; // 4% (goes to Geneis Locker contract)
    uint256 public constant BONDING_AMOUNT = (TOTAL_SUPPLY * 42) / 100; // 42%
    uint256 public constant AMM_SEED_AMOUNT =
        (TOTAL_SUPPLY * 0.3333333333e18) / 100e18; // 0.33% used to seed AMM
    uint256 public constant VESTING_AMOUNT =
        (TOTAL_SUPPLY * 38) / 100 - AMM_SEED_AMOUNT; // 38% (20% Team + 8% Investors + 7% Company Reserves + 3% DAO)
    uint256 public constant AIRDROP_CLAIM_PERIOD = 180 days; // 6 months
    uint256 public constant GENESIS_LOCKER_LOCK_TIME = 26 weeks; // 26 weeks
    uint256 public constant STAKER_UNSTAKE_DELAY = 5 days; // 5 days
    uint256 public constant INITIAL_TLX_PER_SECOND = 0.6806e18; // Roughly 1.18 million TLX in first period (20 days)
    uint256 public constant PERIOD_DECAY_MULTIPLIER = 0.9719981714285e18; // Very roughly gives 40% of TLX bonding allocation in first year
    uint256 public constant PERIOD_DURATION = 20 days;
    uint256 public constant BASE_FOR_ALL_TLX = 15_000e18; // Very roughly means it is 'worth' executing once every 3 days
    uint256 public constant VESTING_DURATION = 365 days; // 1 year
    uint256 public constant REBALANCE_FEE = 5e18; // 5 sUSD
    uint256 public constant REBALANCE_BASE_NEXT_ATTEMPT_DELAY = 1 minutes; // 1 minute (doubles each attempt)
    uint256 public constant MAX_BASE_ASSET_AMOUNT_BUFFER = 0.2e18; // 20%
    uint256 public constant REDEMPTION_FEE = 0.005e18; // 0.5%
    uint256 public constant REBATE_PERCENT = 0.5e18; // 50%
    uint256 public constant EARNINGS_PERCENT = 0.5e18; // 50%
    uint256 public constant REBALANCE_THRESHOLD = 0.25e18; // 25%
    uint256 public constant STREAMING_FEE = 0.02e18; // 2%
    uint256 public constant MAX_REBALANCES = 2; // The maximum number of rebalances that can be performed in a single transaction

    // Bytes
    bytes32 public constant MERKLE_ROOT =
        bytes32(
            0x537a09e5e15c723df3b5f7594ff675fcae57bc5542a98579992a94c8027fa619
        ); // For the airdrop, generated from data/snapshot.json using script/compute-merkle-root.js
}
