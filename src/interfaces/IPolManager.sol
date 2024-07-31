// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IPolManager {
    struct TokenToRedeem {
        address tokenAddress;
        uint256 amount;
    }
    event RedeemFailed(address indexed tokenAddress, uint256 amount);

    function redeemTokens(
        TokenToRedeem[] calldata tokensToRedeem,
        uint256 minAmountOut
    ) external returns (uint256);
}
