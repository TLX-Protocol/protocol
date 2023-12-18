// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Config} from "./Config.sol";
import {Symbols} from "./Symbols.sol";

library LeveragedTokens {
    struct LeveragedTokenData {
        string targetAsset;
        uint256[] leverageOptions;
        uint256 rebalanceThreshold;
    }

    // TODO: Set these with the actual values we want
    function tokens() internal pure returns (LeveragedTokenData[] memory) {
        LeveragedTokenData[] memory tokens_ = new LeveragedTokenData[](3);

        uint256[] memory leverageOptions_ = new uint256[](3);
        leverageOptions_[0] = 1e18;
        leverageOptions_[1] = 3e18;
        leverageOptions_[2] = 10e18;

        tokens_[0] = LeveragedTokenData({
            targetAsset: Symbols.UNI,
            leverageOptions: leverageOptions_,
            rebalanceThreshold: Config.REBALANCE_THRESHOLD
        });
        tokens_[1] = LeveragedTokenData({
            targetAsset: Symbols.ETH,
            leverageOptions: leverageOptions_,
            rebalanceThreshold: Config.REBALANCE_THRESHOLD
        });
        tokens_[2] = LeveragedTokenData({
            targetAsset: Symbols.BTC,
            leverageOptions: leverageOptions_,
            rebalanceThreshold: Config.REBALANCE_THRESHOLD
        });

        return tokens_;
    }
}
