# Protocol Overview

Below is a proposed architecture for the TLX Protocol.

## Core Contracts

Contracts for the delivery and maintenance of the Leveraged Tokens.

### Address Provider

The `AddressProvider` stores the addresses of all of the key contracts in the protocol.
Including but not limited to:

- `LeveragedTokenFactory`
- `PositionManagerFactory`
- `DerivativesHandler`

It will also have admin functions for modifying a subset of these such as the `DerivativesHandler`.
Most other contracts will have the `AddressProvider` as a dependency and will use it to get the addresses of other contracts.

### Leveraged Token Factory

The `LeveragedTokenFactory` is responsible for creating new `LeveragedToken` contracts.
It will:

- Have one admin function `createLeveragedTokens(address target, uint256 targetLeverage)` which will create a matching long and short leveraged token for the given inputs.
- Validate inputs to ensure a matching leveraged token doesn't already exist and that the values are within thresholds
- Validate that a `PositionManager` already exists for the target token.

It will expose several views for querying these `LeverageToken`s such as:

- `allTokens` Returns all Leveraged Tokens
- `longTokens` Returns all Long Leveraged Tokens
- `shortTokens` Returns all Short Leveraged Tokens
- `allTokens(address target)` Returns all Leveraged Tokens for the given target asset
- `longTokens(address target)` Returns all Long Leveraged Tokens for the given target asset
- `shortTokens(address target)` Returns all Short Leveraged Tokens for the given target asset
- `getToken(address target, uint256 targetLeverage, bool isLong)` Returns the Leveraged Token for the given target asset and leverage
- `tokenExists(address target, uint256 targetLeverage, bool isLong)` Returns true if the Leveraged Token for the given target asset and leverage exists
- `pair(address token)` Returns the Leveraged Tokens inverse pair (e.g. ETH3L -> ETH3S)

### Leveraged Token

The `LeveragedToken` contract is the ERC20 that represents each leveraged token.
It will extend the `IERC20Metadata` interface with standard functionality such as name and decimals.
It will have additional views:

- `targetAsset` The target asset of the leveraged token
- `targetLeverage` The target leverage of the leveraged token (3 decimals)
- `isLong` If the leveraged token is long or short

The convention of leveraged tokens will be as follows:

- Name: `[symbol] [leverage]x [Direction]`
- Symbol: `[symbol][leverage][DirectionInitial]`

E.g. for Uniswap 2x Long it would be:

- Name: `UNI 2x Long`
- Symbol `UNI2L`

### Position Manager Factory

The `PositionManagerFactory` is responsible for creating new `PositionManager` contracts, and exposing views to query and manage these `PositionManager` contracts.
It will:

- Have some admin function such as `createPositionManager` that would take a target asset such as `UNI` and deploy a new `PositionManager` contract for it
- Validate that we don't already have a `PositionManager` for that target token
- Store all of these addresses in storage with some view to query them such as `getPositionManagers`

### Position Manager

The `PositionManager` contract can be considered the 'core' contract of the procotol, it will handle most of the logic and orchestration.
It will:

- Mint new `LeveragedTokens` from deposited USDC, and redeem `LeveragedTokens` back for USDC
- Create new `LeveragedTokens` for the target asset and expose views for querying them
- Handle the matching of Long and Short positions to offset profits and losses between `LeveragedTokens`
- Orchestrate calls to the `DerivativesHandler` for taking out long or short positions to fill any unmatched liquidity
- Expose some `rebalance` function that rewards users for rebalancing the positions
- Charge fees on tokens and transfer to the `Locker`

### Derivatives Handler

The `DerivativesHandler` is responsible for taking out positions on external protocols (e.g. GMX) to cover unmatched liquidity.
It will:

- Be a generic wrapper for these protocols, allowing us to update the protocol we use for these external positions by creating a new `DerivativesHandler` for a new source of liquidity and updating to that.
- Use delegatecall for interractions so that the positions are held by the `PositionManager`.

### Position Equalizer

The `PositionEqualizer` contract accepts donations of `LeveragedTokens`.
It will hold these `LeveragedToken`s indefinitely, and can be considered POL (Protocol Owned Liquidity).
It will have a function `equalize` which will move these `LeveragedTokens` around from Long to Short or visa versa with the goal of creating the most balanced state for the Positions.
This reduces needed exposure on GMX, therefore reducing fees for users.

## Tokenomics Contracts

Contracts to support the TLX token, inflation, and fee distribution.

### TLX Token

The `TLXToken` will be the ERC20 for the native token of the TLX protocol.
It will:

- Extend the `IERC20Metadata` interface with standard functionality.
- Have 18 decimals
- Have the name: "TLX Token"
- Have the symbol "TLX"

It will have two minters, the `Airdrop` and `Bonding` contracts

### Airdrop

The `Airdrop` contract will be responsible for the initial airdrop of TLX tokens (currently planned for GMX holders).
It will mint `TLX` as needed and distributed to users based on their claimable amount via a `claim` function.
It will have a function that can be called after 6 months to return any unclaimed TLX to the treasury.

### Locker

TODO

### Bonding

TODO
