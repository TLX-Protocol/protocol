// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ILeveragedToken is IERC20Metadata {
    error NotAuthorized();

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    // The target asset of the leveraged token
    function targetAsset() external view returns (address);

    // The target leverage of the leveraged token (2 decimals)
    function targetLeverage() external view returns (uint256);

    // If the leveraged token is long or short
    function isLong() external view returns (bool);
}
