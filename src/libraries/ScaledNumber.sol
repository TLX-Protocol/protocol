// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

library ScaledNumber {
    uint8 internal constant _DEFAULT_DECIMALS = 18;

    function scaleFrom(
        uint256 value,
        uint8 decimals
    ) internal pure returns (uint256) {
        if (decimals == _DEFAULT_DECIMALS) return value;

        if (decimals > _DEFAULT_DECIMALS) {
            return value / 10 ** (decimals - _DEFAULT_DECIMALS);
        }

        return value * 10 ** (_DEFAULT_DECIMALS - decimals);
    }

    function scaleTo(
        uint256 value,
        uint8 decimals
    ) internal pure returns (uint256) {
        if (decimals == _DEFAULT_DECIMALS) return value;

        if (decimals > _DEFAULT_DECIMALS) {
            return value * 10 ** (decimals - _DEFAULT_DECIMALS);
        }

        return value / 10 ** (_DEFAULT_DECIMALS - decimals);
    }

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
}
