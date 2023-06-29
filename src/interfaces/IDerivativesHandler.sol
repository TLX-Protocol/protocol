// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IDerivativesHandler {
    // To be called using delegatecall.
    // Initializes the caller for trading derivatives via the DerivativesHandler.
    function initialize() external;
}
