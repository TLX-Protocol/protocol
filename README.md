# TLX

[![Tests](https://github.com/TLX-Protocol/protocol-dev/actions/workflows/ci.yml/badge.svg)](https://github.com/TLX-Protocol/protocol-dev/actions/workflows/ci.yml)

This repository contains the core smart contracts for the TLX Protocol.

## Licensing

The primary license for TLX is `GPL-3.0`.

## Documentation

### Overview

TLX is a protocol that allows users to mint and redeem leveraged tokens. The liquidity for these tokens is provided by Synthetix. A referral system is in place that allows for discounts of fees for users, and a share of fees for the referrers. All protocol changes go through a Timelock that has a delay for key changes.

The native token of TLX is `TLX`. Leveraged Tokens can be bonded to receive `TLX` tokens. `TLX` tokens are also distributed to some team members and investors through a vesting schedule. A fee is charged on the Leveraged Tokens which is sent to the staker. Users can stake their TLX to receive a share of these fees. An airdrop will be held when the token is live for a set of users to be able to claim `TLX`.

### Address Provider

The `AddressProvider` contract is responsible for managing all of the core contract and user addresses needed throughout the protocol. Addresses are stored with a key mapping, the keys can be found in the `AddressKeys` library. A function exists to allow the contract owner to freeze an address. This is to be used on deployment to freeze certain addresses that should not change, including:

- `airdrop`
- `bonding`
- `leveragedTokenFactory`
- `tlxToken`
- `vesting`

No contracts should store any address other than the `AddressProvider` address, and should use this to query everything needed.

### Parameter Provider

The `ParameterProvider` contract is responsible for managing all of the core parameters for the protocol. Most parameters are stored with a key mapping, the keys can be found in the `ParameterKeys` library. There is also an additional storage and system for rebalance thresholds which are stored per leveraged token. These can be changed by the owner, but also the `LeveragedTokenFactory`. The reason they can be changed by the `LeveragedTokenFactory` is so that they can be set on the deployment of the leveraged tokens.

### Synthetix Handler

The `SynthetixHandler` contract is responsible for abstracting away the Synthetix integration, exposing useful views and functions to help with the management of positions. It is to be called by the `LeveragedToken` contract. The functions that modify state are intended to be called via delegateCall so the Leveraged Tokens are still the owners of the assets.

### Leveraged Token

The `LeveragedToken` contract can be considered the 'core' contract of the product. It is responsible for minting new Leveraged Tokens, redeeming Leveraged Tokens, and handling rebalances. When a Leveraged Token is created, a few parameters are set:

- `name`: The name of the Leveraged Token
- `symbol`: The symbol of the Leveraged Token
- `targetAsset`: Which asset this Leveraged Token should track
- `targetLeverage`: What leverage the Leveraged Token should track
- `isLong`: If the Leveraged Token is long or short

The goal of the Leveraged Token is to stay within a range of leverage, it should be between the `targetLeverage` plus and minus the `rebalanceThreshold` for that leveraged Token. When the token is outside that range, the `canRebalance` view should generally return `true`. This will then be handled by the keeper to call the `rebalance` function.

Rebalancing should do a few key steps. First, it should verify that we actually can rebalance. Next, it should charge the `rebalanceFee`, which is a flat fee charged to the Leveraged Token holders per rebalance to cover keeper maintenance costs. It should then charge a streaming fee and send that to the staker. Finally, it should submit an update on Synthetix to bring the leverage back in line with the target.

When minting new Leveraged Tokens, the contract should mint an amount of Leveraged Tokens based on the exchange rate of the Leveraged Tokens relative to the Base Asset (sUSD). It then deposits the users' sUSD as additional margin. Finally, if the Leveraged Token is not balanced, it should rebalance it. Note that it does not charge the rebalance fee in this case, as there is no keeper cost to cover.

When redeeming Leveraged Tokens, the contract sends the user an amount of sUSD back dependent on the exchange rate. It charges a redemption fee and sends that to the staker. Finally, if the Leveraged Token is not balanced, it rebalances it. Note that it does not charge the rebalance fee in this case, as there is no keeper cost to cover.

### Leveraged Token Factory

The `LeveragedTokenFactory` is responsible for deploying new Leveraged Tokens, and exposing views to query them.

### Referrals

The `Referrals` contract is responsible for managing the referral system for TLX. The owner has the ability to add new referrers and assign them a code. From there, these referrers will share their code with users. Users can then `register` to use that referral code. Users earn a rebate on their fees thanks to the referral codes, and referrers receive earnings in the form of fee share. These can be claimed by either party with the `claimEarnings` function.

### TLX Token

The `TlxToken` contract is the governance token of the TLX protocol. It will be deployed shortly before the core protocol. It can be staked in the `Staker` contract.

### Airdrop

The `Airdrop` contract is responsible for allowing users to claim an airdrop of `TLX` tokens. Users have until a deadline to claim their tokens, after that, the owner can claim the remaining tokens to the treasury.

### Vesting

The `Vesting` contract is responsible for distributing vested tokens to the team and investors. It has several views to help users see how many tokens they have vesting and their status. And a `claim` function for claiming `TLX` tokens. There is also a system for adding a delegate that can claim tokens on a user's behalf.

### Bonding

Bonding is one of the main ways `TLX` tokens are distributed to users. The `Bonding` contract is responsible for managing this. The bonding contract will be deployed at the same time as the `TLX` token, but bonding will not be live until the protocol is live, and is made live with the `live` function. Users can bond Leveraged Tokens, and get `TLX` in return. The amount of `TLX` they receive increases over time until someone bonds.

### Staker

The staker is where users can stake their `TLX`. Staked `TLX` is staked indefinitely, but at any time a user can call `prepareUnstake` to prepare an unstake. After the delay period, users can call `unstake` to receive their `TLX` tokens back. If they change their mind during an unstake and would like to restake, they can do so with the `restake` function. When staking `TLX`, users receive a share of fees that accrue in the Staker, they can claim these at any time with the `claim` function. Users do not earn fees while they have an unstake prepared. Claiming will be disabled by default, but can be enabled through governance. Staked `TLX` has a `balanceOf` function, similar to an ERC20, which returns how many `TLX` tokens they have staked, this will be used on Snapshot for governance.

### Timelock

The `Timelock` contract will be set as the owner for all other contracts. It is responsible for adding a delay to function calls so that users have time to review the changes. It has functions for creating a new proposed change, cancelling a proposed change, and executing a proposed change. It also has several views for seeing the current state. The delays can be set for different function calls so there is granular control over these.

## Helpers

The helpers in directory `src/helpers` are not considered part of the core protocol. They are lightweight wrappers used to help with integration of off-chain components such as the UI or analytics ect.
