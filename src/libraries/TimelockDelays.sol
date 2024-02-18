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

    function delays() internal pure returns (TimelockDelay[] memory) {
        TimelockDelay[] memory delays_ = new TimelockDelay[](0);

        return delays_;
    }
}
