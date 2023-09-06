// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ILeveragedToken is IERC20Metadata {
    error NotAuthorized();

    /**
     * @notice Mint leveraged tokens to the specified account.
     * @param account The account to mint to.
     * @param amount The amount to mint.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice Burn leveraged tokens from the specified account.
     * @param account The account to burn from.
     * @param amount The amount to burn.
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice Returns the target asset of the leveraged token.
     * @return targetAsset The target asset of the leveraged token.
     */
    function targetAsset() external view returns (address targetAsset);

    /**
     * @notice Returns the target leverage of the leveraged token.
     * @return targetLeverage The target leverage of the leveraged token.
     */
    function targetLeverage() external view returns (uint256 targetLeverage);

    /**
     * @notice Returns if the leveraged token is long or short, `true` for long and `false` for short.
     * @return long `true` if the leveraged token is long and `false` if the leveraged token is short.
     */
    function isLong() external view returns (bool long);
}
