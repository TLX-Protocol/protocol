// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";

contract LeveragedToken is ILeveragedToken, ERC20 {
    address public immutable override targetAsset;
    uint256 public immutable override targetLeverage;
    bool public immutable override isLong;

    address internal immutable _positionManager;

    modifier onlyPositionManager() {
        if (msg.sender != _positionManager) revert NotAuthorized();
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address targetAsset_,
        uint256 targetLeverage_,
        bool isLong_,
        address positionManager_
    ) ERC20(name_, symbol_) {
        targetAsset = targetAsset_;
        targetLeverage = targetLeverage_;
        isLong = isLong_;
        _positionManager = positionManager_;
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
