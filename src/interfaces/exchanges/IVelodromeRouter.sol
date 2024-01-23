// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IVelodromeRouter {
    struct Route {
        address from;
        address to;
        bool stable;
        address factory;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        Route[] memory routes
    ) external view returns (uint256[] memory amounts);
}
