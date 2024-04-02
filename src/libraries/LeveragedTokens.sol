// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Config} from "./Config.sol";
import {Symbols} from "./Symbols.sol";

library LeveragedTokens {
    struct LeveragedTokenData {
        string targetAsset;
        uint256[] leverageOptions;
        uint256[] rebalanceThreshold;
    }

    function tokens() internal pure returns (LeveragedTokenData[] memory) {
        LeveragedTokenData[] memory tokens_ = new LeveragedTokenData[](5);

        uint256[] memory leverageOptions_ = new uint256[](3);
        leverageOptions_[0] = 1e18;
        leverageOptions_[1] = 2e18;
        leverageOptions_[2] = 5e18;

        // Tailored rebalance thresholds for each asset and leverage factor:

        uint256[] memory ethThresholds_ = new uint256[](3);
        ethThresholds_[0] = 0.03e18;
        ethThresholds_[1] = 0.05e18;
        ethThresholds_[2] = 0.10e18;

        uint256[] memory btcThresholds_ = new uint256[](3);
        btcThresholds_[0] = 0.03e18;
        btcThresholds_[1] = 0.05e18;
        btcThresholds_[2] = 0.1e18;

        uint256[] memory solThresholds_ = new uint256[](3);
        solThresholds_[0] = 0.05e18;
        solThresholds_[1] = 0.10e18;
        solThresholds_[2] = 0.15e18;

        uint256[] memory linkThresholds_ = new uint256[](3);
        linkThresholds_[0] = 0.05e18;
        linkThresholds_[1] = 0.10e18;
        linkThresholds_[2] = 0.15e18;

        uint256[] memory opThresholds_ = new uint256[](3);
        opThresholds_[0] = 0.05e18;
        opThresholds_[1] = 0.10e18;
        opThresholds_[2] = 0.20e18;

        tokens_[0] = LeveragedTokenData({
            targetAsset: Symbols.ETH,
            leverageOptions: leverageOptions_,
            rebalanceThreshold: ethThresholds_
        });
        tokens_[1] = LeveragedTokenData({
            targetAsset: Symbols.BTC,
            leverageOptions: leverageOptions_,
            rebalanceThreshold: btcThresholds_
        });
        tokens_[2] = LeveragedTokenData({
            targetAsset: Symbols.SOL,
            leverageOptions: leverageOptions_,
            rebalanceThreshold: solThresholds_
        });
        tokens_[3] = LeveragedTokenData({
            targetAsset: Symbols.LINK,
            leverageOptions: leverageOptions_,
            rebalanceThreshold: linkThresholds_
        });
        tokens_[4] = LeveragedTokenData({
            targetAsset: Symbols.OP,
            leverageOptions: leverageOptions_,
            rebalanceThreshold: opThresholds_
        });

        return tokens_;
    }
}
