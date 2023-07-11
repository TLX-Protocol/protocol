// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {ITlxToken} from "./interfaces/ITlxToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract TlxToken is ITlxToken, ERC20 {
    uint256 internal constant _MAX_SUPPLY = 10_000_000e18;
    uint256 internal constant _AIRDRIP_MAX_SUPPLY = 1_000_000e18;
    uint256 internal constant _BONDING_MAX_SUPPLY = 7_500_000e18;
    uint256 internal constant _TREASURY_MAX_SUPPLY = 500_000e18;
    uint256 internal constant _VESTING_MAX_SUPPLY = 1_000_000e18;

    address internal immutable _addressProvider;

    uint256 public override airdropTotalSupply;
    uint256 public override bondingTotalSupply;
    uint256 public override treasuryTotalSupply;
    uint256 public override vestingTotalSupply;

    constructor(address addressProvider_) ERC20("TLX Token", "TLX") {
        uint256 totalMaxSupply = _AIRDRIP_MAX_SUPPLY +
            _BONDING_MAX_SUPPLY +
            _TREASURY_MAX_SUPPLY;
        if (totalMaxSupply != _MAX_SUPPLY) revert InvalidMaxSupply();

        _addressProvider = addressProvider_;
    }

    function airdropMint(address to, uint256 amount) external override {
        if (msg.sender != IAddressProvider(_addressProvider).airdrop())
            revert NotAuthorized();
        if (airdropTotalSupply == _AIRDRIP_MAX_SUPPLY)
            revert ExceedsMaxSupply();
        if (airdropTotalSupply + amount > _AIRDRIP_MAX_SUPPLY) {
            amount = _AIRDRIP_MAX_SUPPLY - airdropTotalSupply;
        }
        airdropTotalSupply += amount;
        _mint(to, amount);
    }

    function bondingMint(address to, uint256 amount) external override {
        if (msg.sender != IAddressProvider(_addressProvider).bonding())
            revert NotAuthorized();
        if (bondingTotalSupply == _BONDING_MAX_SUPPLY)
            revert ExceedsMaxSupply();
        if (bondingTotalSupply + amount > _BONDING_MAX_SUPPLY) {
            amount = _BONDING_MAX_SUPPLY - bondingTotalSupply;
        }
        bondingTotalSupply += amount;
        _mint(to, amount);
    }

    function treasuryMint(address to, uint256 amount) external override {
        if (msg.sender != IAddressProvider(_addressProvider).treasury())
            revert NotAuthorized();
        if (treasuryTotalSupply == _TREASURY_MAX_SUPPLY)
            revert ExceedsMaxSupply();
        if (treasuryTotalSupply + amount > _TREASURY_MAX_SUPPLY) {
            amount = _TREASURY_MAX_SUPPLY - treasuryTotalSupply;
        }
        treasuryTotalSupply += amount;
        _mint(to, amount);
    }

    function vestingMint(address to, uint256 amount) external override {
        if (msg.sender != IAddressProvider(_addressProvider).vesting())
            revert NotAuthorized();
        if (vestingTotalSupply == _VESTING_MAX_SUPPLY)
            revert ExceedsMaxSupply();
        if (vestingTotalSupply + amount > _VESTING_MAX_SUPPLY) {
            amount = _VESTING_MAX_SUPPLY - vestingTotalSupply;
        }
        vestingTotalSupply += amount;
        _mint(to, amount);
    }

    function airdropMaxSupply() public pure override returns (uint256) {
        return _AIRDRIP_MAX_SUPPLY;
    }

    function bondingMaxSupply() public pure override returns (uint256) {
        return _BONDING_MAX_SUPPLY;
    }

    function treasuryMaxSupply() public pure override returns (uint256) {
        return _TREASURY_MAX_SUPPLY;
    }

    function vestingMaxSupply() public pure override returns (uint256) {
        return _VESTING_MAX_SUPPLY;
    }

    function maxSupply() public pure override returns (uint256) {
        return _MAX_SUPPLY;
    }
}
