// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

library ScaledNumber {
    uint8 internal constant _DEFAULT_DECIMALS = 18;

    function div(
        uint256 value,
        uint256 divisor
    ) internal pure returns (uint256) {
        return (value * 10 ** _DEFAULT_DECIMALS) / divisor;
    }

    function mul(
        uint256 value,
        uint256 multiplier
    ) internal pure returns (uint256) {
        return (value * multiplier) / 10 ** _DEFAULT_DECIMALS;
    }

    function mul(
        int256 value,
        int256 multiplier
    ) internal pure returns (int256) {
        return (value * multiplier) / int256(10 ** _DEFAULT_DECIMALS);
    }

    function absSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }
}
