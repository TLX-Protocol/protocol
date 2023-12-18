// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {DeploymentScript} from "./shared/DeploymentScript.s.sol";

import {Contracts} from "../../src/libraries/Contracts.sol";
import {AddressKeys} from "../../src/libraries/AddressKeys.sol";
import {Config} from "../../src/libraries/Config.sol";
import {LeveragedTokens} from "../../src/libraries/LeveragedTokens.sol";

import {IAddressProvider} from "../../src/interfaces/IAddressProvider.sol";
import {IBonding} from "../../src/interfaces/IBonding.sol";

import {LeveragedTokenFactory} from "../../src/LeveragedTokenFactory.sol";
import {Referrals} from "../../src/Referrals.sol";
import {SynthetixHandler} from "../../src/SynthetixHandler.sol";
import {ChainlinkAutomation} from "../../src/ChainlinkAutomation.sol";

contract ProtocolDeployment is DeploymentScript {
    function _run() internal override {
        // Getting deployed contracts
        IAddressProvider addressProvider = IAddressProvider(
            _getDeployedAddress("AddressProvider")
        );
        IBonding bonding = IBonding(_getDeployedAddress("Bonding"));

        // Leveraged Token Factory Deployment
        LeveragedTokenFactory leveragedTokenFactory = new LeveragedTokenFactory(
            address(addressProvider),
            Config.MAX_LEVERAGE
        );
        _deployedAddress(
            "LeveragedTokenFactory",
            address(leveragedTokenFactory)
        );
        addressProvider.updateAddress(
            AddressKeys.LEVERAGED_TOKEN_FACTORY,
            address(leveragedTokenFactory)
        );

        // Referrals Deployment
        Referrals referrals = new Referrals(
            address(addressProvider),
            Config.REBATE_PERCENT,
            Config.EARNINGS_PERCENT
        );
        _deployedAddress("Referrals", address(referrals));
        addressProvider.updateAddress(
            AddressKeys.REFERRALS,
            address(referrals)
        );

        // SynthetixHandler Deployment
        SynthetixHandler synthetixHandler = new SynthetixHandler(
            address(addressProvider),
            address(Contracts.PERPS_V2_MARKET_DATA)
        );
        _deployedAddress("SynthetixHandler", address(synthetixHandler));
        addressProvider.updateAddress(
            AddressKeys.SYNTHETIX_HANDLER,
            address(synthetixHandler)
        );

        // ChainlinkAutomation Deployment
        ChainlinkAutomation chainlinkAutomation = new ChainlinkAutomation(
            address(addressProvider),
            Config.MAX_REBALANCES
        );
        _deployedAddress("ChainlinkAutomation", address(chainlinkAutomation));

        // Deploying Leveraged Tokens
        LeveragedTokens.LeveragedTokenData[]
            memory leveragedTokenData = LeveragedTokens.tokens();
        for (uint256 i; i < leveragedTokenData.length; i++) {
            uint256[] memory leverageOptions_ = leveragedTokenData[i]
                .leverageOptions;
            for (uint256 j; j < leverageOptions_.length; j++) {
                leveragedTokenFactory.createLeveragedTokens(
                    leveragedTokenData[i].targetAsset,
                    leverageOptions_[j],
                    leveragedTokenData[i].rebalanceThreshold
                );
            }
        }

        // Launching bonding
        bonding.launch();
    }
}
