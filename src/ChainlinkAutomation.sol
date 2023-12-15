// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {AutomationCompatibleInterface} from "chainlink/src/v0.8/automation/AutomationCompatible.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {Errors} from "./libraries/Errors.sol";

import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract ChainlinkAutomation is AutomationCompatibleInterface, Ownable {
    uint256 internal immutable _maxRebalances;

    IAddressProvider internal immutable _addressProvider;

    event UpkeepPerformed(address[] rebalancableTokens_);

    error NoRebalancableTokens();

    constructor(address addressProvider_, uint256 maxReblances_) {
        _addressProvider = IAddressProvider(addressProvider_);
        _maxRebalances = maxReblances_;
    }

    function performUpkeep(bytes calldata performData) external onlyOwner {
        address[] memory rebalancableTokens_ = abi.decode(
            performData,
            (address[])
        );

        uint256 rebalancableTokensCount_ = rebalancableTokens_.length;
        if (rebalancableTokensCount_ == 0) revert NoRebalancableTokens();

        for (uint256 i; i < rebalancableTokensCount_; i++) {
            ILeveragedToken(rebalancableTokens_[i]).rebalance();
        }

        emit UpkeepPerformed(rebalancableTokens_);
    }

    function checkUpkeep(
        bytes calldata
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        address[] memory tokens_ = _addressProvider
            .leveragedTokenFactory()
            .allTokens();

        address[] memory rebalancableTokens_ = new address[](_maxRebalances);
        uint256 rebalancableTokensCount_;
        for (uint256 i; i < tokens_.length; i++) {
            if (!ILeveragedToken(tokens_[i]).canRebalance()) continue;
            rebalancableTokens_[rebalancableTokensCount_] = tokens_[i];
            rebalancableTokensCount_++;
            if (rebalancableTokensCount_ == _maxRebalances) break;
        }

        if (rebalancableTokensCount_ == 0) return (false, "");
        upkeepNeeded = true;

        // solhint-disable-next-line
        assembly {
            mstore(rebalancableTokens_, rebalancableTokensCount_)
        }
        performData = abi.encode(rebalancableTokens_);
    }
}
