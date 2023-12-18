// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IBonding} from "../interfaces/IBonding.sol";
import {IParameterProvider} from "../interfaces/IParameterProvider.sol";

import {Config} from "./Config.sol";
import {Symbols} from "./Symbols.sol";

library TimelockDelays {
    struct TimelockDelay {
        bytes4 selector;
        uint256 delay;
    }

    // TODO: Set these with the actual values we want
    function delays() internal pure returns (TimelockDelay[] memory) {
        TimelockDelay[] memory delays_ = new TimelockDelay[](3);

        delays_[0] = TimelockDelay({
            selector: IAddressProvider.updateAddress.selector,
            delay: 1 days
        });
        delays_[1] = TimelockDelay({
            selector: IBonding.setBaseForAllTlx.selector,
            delay: 2 days
        });
        delays_[2] = TimelockDelay({
            selector: IParameterProvider.updateRebalanceThreshold.selector,
            delay: 3 days
        });

        return delays_;
    }
}
