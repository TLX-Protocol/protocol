# TLX Protocol

## Overview

TODO

## Contracts

### Address Manager

TODO

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

### Derivatives Handler

The `DerivativesHandler` is responsible for taking out positions on external protocols (e.g. GMX) to cover unmatched liquidity.
It will be a generic wrapper for these protocols, allowing us to update the protocol we use for these external positions by creating a new `DerivativesHandler` for a new source of liquidity and updating to that.
It will use delegatecall for interractions so that the positions are held by the `PositionManager`.
