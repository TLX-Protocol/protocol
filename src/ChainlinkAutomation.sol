// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {AutomationCompatibleInterface} from "chainlink/src/v0.8/automation/AutomationCompatible.sol";

import {Errors} from "./libraries/Errors.sol";

import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract ChainlinkAutomation is AutomationCompatibleInterface {
    uint256 internal constant MAX_REBALANCES = 20;

    IAddressProvider internal immutable _addressProvider;

    address internal immutable _upkeep;

    constructor(address addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
        _upkeep = msg.sender; // TODO Change this to the actual upkeep contract
    }

    function checkUpkeep(
        bytes calldata
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        address[] memory tokens_ = _addressProvider
            .leveragedTokenFactory()
            .allTokens();

        address[] memory rebalancableTokens_ = new address[](MAX_REBALANCES);
        uint256 rebalancableTokensCount_ = 0;
        for (uint256 i = 0; i < tokens_.length; i++) {
            if (!ILeveragedToken(tokens_[i]).canRebalance()) continue;
            upkeepNeeded = true;
            rebalancableTokens_[rebalancableTokensCount_] = tokens_[i];
            rebalancableTokensCount_++;
            if (rebalancableTokensCount_ == MAX_REBALANCES) break;
        }

        if (!upkeepNeeded) return (false, "");
        performData = abi.encode(rebalancableTokensCount_, rebalancableTokens_);
    }

    function performUpkeep(bytes calldata performData) external {
        if (msg.sender != _upkeep) revert Errors.NotAuthorized();

        (
            uint256 rebalancableTokensCount_,
            address[] memory rebalancableTokens_
        ) = abi.decode(performData, (uint256, address[]));

        if (rebalancableTokensCount_ == 0) return;

        for (uint256 i = 0; i < rebalancableTokensCount_; i++) {
            ILeveragedToken(rebalancableTokens_[i]).rebalance();
        }
    }
}
