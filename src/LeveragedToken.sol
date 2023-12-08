// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Errors} from "./libraries/Errors.sol";

import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";

contract LeveragedToken is ILeveragedToken, ERC20 {
    string public override targetAsset;
    uint256 public immutable override targetLeverage;
    bool public immutable override isLong;
    address public immutable override positionManager;

    modifier onlyPositionManager() {
        if (msg.sender != positionManager) revert Errors.NotAuthorized();
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory targetAsset_,
        uint256 targetLeverage_,
        bool isLong_,
        address positionManager_
    ) ERC20(name_, symbol_) {
        targetAsset = targetAsset_;
        targetLeverage = targetLeverage_;
        isLong = isLong_;
        positionManager = positionManager_;
    }

    function mint(
        address account,
        uint256 amount
    ) external override onlyPositionManager {
        _mint(account, amount);
    }

    function burn(
        address account,
        uint256 amount
    ) external override onlyPositionManager {
        _burn(account, amount);
    }
}
