// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IPositionManager} from "./IPositionManager.sol";

interface ILeveragedToken is IERC20Metadata {
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
    function targetAsset() external view returns (string memory targetAsset);

    /**
     * @notice Returns the target leverage of the leveraged token.
     * @return targetLeverage The target leverage of the leveraged token.
     */
    function targetLeverage() external view returns (uint256 targetLeverage);

    /**
     * @notice Returns if the leveraged token is long or short.
     * @return isLong `true` if the leveraged token is long and `false` if the leveraged token is short.
     */
    function isLong() external view returns (bool isLong);

    /**
     * @notice Returns the position manager of the leveraged token.
     * @return positionManager The position manager of the leveraged token.
     */
    function positionManager()
        external
        view
        returns (IPositionManager positionManager);

    /**
     * @notice Returns if the leveraged token is active,
     * @dev A token is active if it still has some positive exchange rate (i.e. has not been liquidated).
     * @return isActive If the leveraged token is active.
     */
    function isActive() external view returns (bool isActive);
}
