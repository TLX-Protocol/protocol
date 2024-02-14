// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IBaseStaker} from "./IBaseStaker.sol";

interface IStaker is IBaseStaker {
    /**
     * @notice Returns the symbol of the Staker.
     * @return symbol The symbol of the Staker.
     */
    function symbol() external view returns (string memory symbol);

    /**
     * @notice Returns the name of the Staker.
     * @return name The name of the Staker.
     */
    function name() external view returns (string memory name);
}
