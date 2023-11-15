// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

library Contracts {
    // Chainlink
    address public constant UNI_USD_ORACLE =
        0x11429eE838cC01071402f21C219870cbAc0a59A0;
    address public constant ETH_USD_ORACLE =
        0x13e3Ee699D1909E989722E753853AE30b17e08c5;
    address public constant BTC_USD_ORACLE =
        0x718A5788b89454aAE3A028AE9c111A29Be6c2a6F;
    address public constant USDC_USD_ORACLE =
        0x16a9FA2FDa030272Ce99B29CF780dFA30361E0f3;
    address public constant CBETH_ETH_ORACLE =
        0x138b809B8472fF09Cd3E075E6EcbB2e42D41d870;
    address public constant SUSD_USD_ORACLE =
        0x7f99817d87baD03ea21E05112Ca799d715730efe;

    // Synthetix
    address public constant PERPS_V2_MARKET_DATA =
        0x340B5d664834113735730Ad4aFb3760219Ad9112;
}
