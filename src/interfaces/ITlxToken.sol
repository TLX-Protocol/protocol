// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ITlxToken is IERC20Metadata {
    error InvalidMaxSupply();
    error NotAuthorized();
    error ExceedsMaxSupply();

    function airdropMint(address to, uint256 amount) external;

    function bondingMint(address to, uint256 amount) external;

    function treasuryMint(address to, uint256 amount) external;

    function vestingMint(address to, uint256 amount) external;

    function airdropMaxSupply() external view returns (uint256);

    function airdropTotalSupply() external view returns (uint256);

    function bondingMaxSupply() external view returns (uint256);

    function bondingTotalSupply() external view returns (uint256);

    function treasuryMaxSupply() external view returns (uint256);

    function treasuryTotalSupply() external view returns (uint256);

    function vestingMaxSupply() external view returns (uint256);

    function vestingTotalSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);
}
