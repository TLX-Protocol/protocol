// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Tokens} from "./Tokens.sol";

library Config {
    // Addresses
    address public constant BASE_ASSET = Tokens.SUSD; // sUSD
    address public constant BINANCE =
        0xacD03D601e5bB1B275Bb94076fF46ED9D753435A; // Used for testing scripts
    address public constant TREASURY = address(1); // Our multisig
    address public constant POL = TREASURY; // Where the bonding tokens ar sent to
    address public constant REBALANCE_FEE_RECEIVER = address(2); // Receiver of rebalance fees (may be treasury to start)
    address public constant CHAINLINK_AUTOMATION_FORWARDER_ADDRESS = address(7); // The forwarder address for Chainlink automation

    // Strings
    string public constant TOKEN_NAME = "TLX DAO Token"; // TLX DAO Token
    string public constant TOKEN_SYMBOL = "TLX"; // TLX

    // Values
    uint256 public constant AIRDROP_AMOUNT = 1_000_000e18; // 1 million TLX
    uint256 public constant BONDING_AMOUNT = 7_500_000e18; // 7.5 million TLX
    uint256 public constant TREASURY_AMOUNT = 500_000e18; // 500k TLX
    uint256 public constant VESTING_AMOUNT = 1_000_000e18; // 1 million TLX
    uint256 public constant AIRDROP_CLAIM_PERIOD = 180 days; // 6 months
    uint256 public constant LOCKER_UNLOCK_DELAY = 7 days; // 1 week
    uint256 public constant INITIAL_TLX_PER_SECOND = 0.09645061728e18; // 250k TLX in first month / 30 days (in seconds)
    uint256 public constant PERIOD_DECAY_MULTIPLIER = 0.966666666666666667e18; // Very roughly gives 30% of supply in first year
    uint256 public constant PERIOD_DURATION = 30 days; // 1 month
    uint256 public constant BASE_FOR_ALL_TLX = 75_000e18; // Very roughly means it is 'worth' executing once every 3 days
    uint256 public constant VESTING_DURATION = 365 days; // 1 year
    uint256 public constant REBALANCE_FEE = 2e18; // 2 sUSD
    uint256 public constant MAX_LEVERAGE = 50e18; // 50x
    uint256 public constant REDEMPTION_FEE = 0.005e18; // 0.5%
    uint256 public constant REBATE_PERCENT = 0.5e18; // 50%
    uint256 public constant EARNINGS_PERCENT = 0.5e18; // 50%
    uint256 public constant REBALANCE_THRESHOLD = 0.25e18; // 25%
    uint256 public constant STREAMING_FEE = 0.02e18; // 2%
    uint256 public constant MAX_REBALANCES = 20; // The maximum number of rebalances that can be performed in a single transaction

    // Bytes
    bytes32 public constant MERKLE_ROOT =
        bytes32(
            0x468a9099f57f82cbafabb8f3f00efa98e5f6d0edd1a937b2aaec7293e6b9156f
        ); // For the airdrop
}
