// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface ILiquidationPointsClaimer {
    function claimLiquidationPoints() external;

    function claimers() external view returns (address[] memory);
}

contract LiquidationPointsClaimer is ILiquidationPointsClaimer {
    address[] internal _claimers;

    function claimLiquidationPoints() external override {
        _claimers.push(msg.sender);
    }

    function claimers() external view override returns (address[] memory) {
        return _claimers;
    }
}
