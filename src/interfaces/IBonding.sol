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

    function bond(
        address leveragedToken,
        uint256 leveragedTokenAmount,
        uint256 minTlxTokensReceived
    ) external returns (uint256 tlxTokensReceived);

    function exchangeRate() external view returns (uint256 exchangeRate);

    function availableTlx() external view returns (uint256 availableTlx);

    function totalTlxBonded() external view returns (uint256 totalTlxBonded);
}
