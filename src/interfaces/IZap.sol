// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IZap {
    event Minted(
        address indexed account,
        uint256 baseAssetAmount,
        uint256 leveragedTokenAmount
    );
    event Redeemed(
        address indexed account,
        uint256 baseAssetAmount,
        uint256 leveragedTokenAmount
    );

    error InvalidAddress();

    function name() external returns (string memory);

    /**
     * @notice Mints the target leveraged tokens to the caller with the given amountIn of the specific stablecoin.
     * @param leveragedTokenAddress Address of target leveraged token to mint
     * @param amountIn The amount of the stablecoin to mint with.
     * @param minLeveragedTokenAmountOut The minimum amount of leveragedTokens to mint (reverts otherwise).
     * @return leveragedTokenAmountOut The amount of leveragedTokens minted.
     */
    function mint(
        address leveragedTokenAddress,
        uint256 amountIn,
        uint256 minLeveragedTokenAmountOut
    ) external returns (uint256 leveragedTokenAmountOut);
}
