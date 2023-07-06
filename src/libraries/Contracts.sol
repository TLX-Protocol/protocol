// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

library Contracts {
    // GMX
    address public constant GMX_VAULT =
        0x489ee077994B6658eAfA855C308275EAd8097C4A;
    address public constant GMX_ROUTER =
        0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064;
    address public constant GMX_POSITION_ROUTER =
        0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868;
    address public constant GMX_ORDER_BOOK =
        0x09f77E8A13De9a35a7231028187e9fD5DB8a2ACB;
    address public constant GMX_READER =
        0x22199a49A999c351eF7927602CFB187ec3cae489;
    address public constant GMX_REWARD_READER =
        0x8BFb8e82Ee4569aee78D03235ff465Bd436D40E0;
    address public constant GMX_ORDER_BOOK_READER =
        0xa27C20A7CF0e1C68C0460706bB674f98F362Bc21;
    address public constant STAKED_GMX =
        0xd2D1162512F927a7e282Ef43a362659E4F2a728F;
    address public constant STAKED_GLP =
        0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;
    address public constant GMX_GLP_MANAGER =
        0x3963FfC9dff443c2A94f21b129D429891E32ec18;
    address public constant GMX_REWARD_ROUTER =
        0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;
    address public constant GMX_GLP_REWARD_ROUTER =
        0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
    address public constant GMX_REFERRAL_STORAGE =
        0xe6fab3F0c7199b0d34d7FbE83394fc0e0D06e99d;
    address public constant GMX_ETH_UNISWAP_POOL =
        0x80A9ae39310abf666A87C743d6ebBD0E8C42158E;

    // Chainlink
    address public constant UNI_USD_ORACLE =
        0x9C917083fDb403ab5ADbEC26Ee294f6EcAda2720;
    address public constant ETH_USD_ORACLE =
        0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    address public constant WBTC_ETH_ORACLE =
        0xc5a90A6d7e4Af242dA238FFe279e9f2BA0c64B2e;
    address public constant USDC_USD_ORACLE =
        0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
}
