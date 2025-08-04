# Scripts

This directory contains utility scripts for managing and monitoring the TLX leveraged token protocol.

## Scripts

### `pause-tokens.js`

A utility script to pause all active leveraged tokens in the protocol.

**Purpose:** Pauses all active leveraged tokens to prevent new deposits and withdrawals during maintenance or emergency situations.

**Features:**
- Connects to the TLX factory contract to get all token addresses
- Checks each token's current pause status and activity state
- Pauses only active, non-paused tokens
- Skips already paused or liquidated tokens
- Provides detailed logging and summary statistics

**Usage:**
```bash
# Set environment variables
export ALCHEMY_URL="your_alchemy_rpc_url"
export PRIVATE_KEY="your_private_key_here"

# Run the script
node script/pause-tokens.js
```

**Environment Variables:**
- `ALCHEMY_URL`: Alchemy RPC endpoint (required)
- `PRIVATE_KEY`: Private key for transaction signing (required)

**Output:**
- Lists each token with its asset, leverage, and direction
- Shows pause status for each token
- Provides summary statistics at the end

### `token-summary.js`

A comprehensive monitoring script that generates detailed reports about all leveraged tokens in the protocol.

**Purpose:** Provides real-time insights into protocol health, TVL, leverage ratios, and token performance.

**Features:**
- Fetches detailed data from the LeveragedTokenHelper contract
- Displays active tokens sorted by TVL
- Shows protocol totals (TVL, Open Interest, Average Leverage)
- Breaks down data by asset and leverage levels
- Lists liquidated tokens with their final states
- Filters out tokens with TVL < 1,000 sUSD for cleaner display

**Usage:**
```bash
# Set environment variables
export ALCHEMY_URL="your_alchemy_rpc_url"

# Run the script
node script/token-summary.js
```

**Environment Variables:**
- `ALCHEMY_URL`: Alchemy RPC endpoint (required)

**Output:**
- Active tokens table with TVL, leverage, and rebalance status
- Protocol totals and averages
- Asset and leverage breakdowns
- Liquidated tokens summary
- Network and timestamp information

### `rebalance-simple.js`

Rebalances all leverage tokens that need it.

**Purpose:** Automatically rebalances leveraged tokens to maintain their target leverage ratios.

**Usage:**
```bash
export PRIVATE_KEY="your_private_key"
export RPC_URL="your_rpc_url"
node script/rebalance-simple.js
```

**Requirements:**
- Your address must be authorized as a rebalancer
- Node.js with ethers.js installed

## Contract Addresses

Both scripts use the following contract addresses (Optimism mainnet):
- **Factory**: `0x5Dd85f51e9fD6aDE8ecc216C07919ecD443eB14d`
- **Helper**: `0xBdAF7A2C4ee313Be468B9250609ba8496131B1f0`

## Dependencies

Both scripts require:
- `ethers` (v6+)
- `dotenv` for environment variable management

Install dependencies:
```bash
npm install ethers dotenv
```

## Security Notes

- The `pause-tokens.js` script requires a private key and will execute transactions
- The `token-summary.js` script is read-only and does not require a private key
- Only run with appropriate permissions and on the correct network
- Always verify contract addresses before execution
- Consider using a dedicated wallet for administrative operations

## Network Support

These scripts are configured for Optimism mainnet but can be adapted for other networks by updating the RPC URL and contract addresses.
