// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";

contract LeveragedToken is ILeveragedToken, ERC20 {
    address public override targetAsset;
    uint256 public override targetLeverage;
    bool public override isLong;

    constructor(
        string memory name_,
        string memory symbol_,
        address target_,
        uint256 targetLeverage_,
        bool isLong_
    ) ERC20(name_, symbol_) {
        targetAsset = target_;
        targetLeverage = targetLeverage_;
        isLong = isLong_;
    }
}
