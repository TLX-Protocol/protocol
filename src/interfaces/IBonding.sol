// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IBonding {
    event Bonded(
        address indexed account,
        address indexed leveragedToken,
        uint256 leveragedTokenAmount,
        uint256 tlxTokensReceived
    );

    error NotLeveragedToken();
    error MinTlxNotReached();
    error ExceedsAvailable();

    /**
     * @notice Bond leveraged tokens for TLX.
     * @param leveragedToken The address of the leveraged token to bond.
     * @param leveragedTokenAmount The amount of leveraged tokens to bond.
     * @param minTlxTokensReceived The minimum amount of TLX tokens to receive.
     * @return tlxTokensReceived The amount of TLX tokens received.
     */
    function bond(
        address leveragedToken,
        uint256 leveragedTokenAmount,
        uint256 minTlxTokensReceived
    ) external returns (uint256 tlxTokensReceived);

    /**
     * @notice Returns the exchange rate between leveraged tokens USDC value and TLX.
     * @return exchangeRate The exchange rate between leveraged tokens USDC value and TLX.
     */
    function exchangeRate() external view returns (uint256 exchangeRate);

    /**
     * @notice Returns the amount of TLX tokens that can be bonded.
     * @return availableTlx The amount of TLX tokens that can be bonded.
     */
    function availableTlx() external view returns (uint256 availableTlx);

    /**
     * @notice Returns the total amount of TLX tokens bonded.
     * @return totalTlxBonded The total amount of TLX tokens bonded.
     */
    function totalTlxBonded() external view returns (uint256 totalTlxBonded);
}
