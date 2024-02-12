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
    uint256 internal immutable _baseNextAttemptDelay;

    mapping(address => uint256) internal _failedCounter;
    mapping(address => uint256) internal _nextAttempt;

    event UpkeepPerformed(address indexed leveragedToken);
    event UpkeepFailed(
        address indexed leveragedToken,
        uint256 nextAttempt,
        uint256 failedCounter
    );

    error NoRebalancableTokens();

    constructor(
        address addressProvider_,
        uint256 maxReblances_,
        uint256 baseNextAttemptDelay_
    ) {
        _addressProvider = IAddressProvider(addressProvider_);
        _maxRebalances = maxReblances_;
        _baseNextAttemptDelay = baseNextAttemptDelay_;
    }

    function performUpkeep(bytes calldata performData) external onlyOwner {
        address[] memory rebalancableTokens_ = abi.decode(
            performData,
            (address[])
        );

        uint256 rebalancableTokensCount_ = rebalancableTokens_.length;
        if (rebalancableTokensCount_ == 0) revert NoRebalancableTokens();

        for (uint256 i; i < rebalancableTokensCount_; i++) {
            address token_ = rebalancableTokens_[i];
            try ILeveragedToken(token_).rebalance() {
                delete _failedCounter[token_];
                delete _nextAttempt[token_];
                emit UpkeepPerformed(token_);
            } catch {
                uint256 scale_ = 2 ** _failedCounter[token_];
                uint256 delay_ = _baseNextAttemptDelay * scale_;
                uint256 nextAttempt_ = block.timestamp + delay_;
                _nextAttempt[token_] = nextAttempt_;
                uint256 failedCounter_ = _failedCounter[token_] + 1;
                _failedCounter[token_] = failedCounter_;
                emit UpkeepFailed(token_, nextAttempt_, failedCounter_);
            }
        }
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
            address token_ = tokens_[i];
            if (!ILeveragedToken(token_).canRebalance()) continue;
            if (_nextAttempt[token_] > block.timestamp) continue;
            rebalancableTokens_[rebalancableTokensCount_] = token_;
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
