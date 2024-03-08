// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {AutomationCompatibleInterface} from "chainlink/src/v0.8/automation/AutomationCompatible.sol";

import {TlxOwnable} from "./utils/TlxOwnable.sol";

import {Errors} from "./libraries/Errors.sol";

import {IChainlinkAutomation} from "./interfaces/IChainlinkAutomation.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";

contract ChainlinkAutomation is IChainlinkAutomation, TlxOwnable {
    uint256 internal immutable _maxRebalances;
    IAddressProvider internal immutable _addressProvider;
    uint256 internal immutable _baseNextAttemptDelay;

    /// @inheritdoc IChainlinkAutomation
    address public override forwarderAddress;
    mapping(address => uint256) internal _failedCounter;
    mapping(address => uint256) internal _nextAttempt;

    constructor(
        address addressProvider_,
        uint256 maxReblances_,
        uint256 baseNextAttemptDelay_
    ) TlxOwnable(addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
        _maxRebalances = maxReblances_;
        _baseNextAttemptDelay = baseNextAttemptDelay_;
    }

    /// @inheritdoc AutomationCompatibleInterface
    function performUpkeep(bytes calldata performData_) external override {
        if (msg.sender != forwarderAddress) revert NotForwarder();

        address[] memory rebalancableTokens_ = abi.decode(
            performData_,
            (address[])
        );

        uint256 rebalancableTokensCount_ = rebalancableTokens_.length;
        if (rebalancableTokensCount_ == 0) revert NoRebalancableTokens();

        for (uint256 i_; i_ < rebalancableTokensCount_; i_++) {
            address token_ = rebalancableTokens_[i_];
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

    /// @inheritdoc IChainlinkAutomation
    function setForwarderAddress(
        address forwarderAddress_
    ) external override onlyOwner {
        if (forwarderAddress_ == forwarderAddress) {
            revert Errors.SameAsCurrent();
        }
        forwarderAddress = forwarderAddress_;
    }

    /// @inheritdoc IChainlinkAutomation
    function resetFailedCounter(
        address leveragedToken_
    ) external override onlyOwner {
        if (_failedCounter[leveragedToken_] == 0) revert Errors.SameAsCurrent();
        delete _failedCounter[leveragedToken_];
        emit FailedCounterReset(leveragedToken_);
    }

    /// @inheritdoc AutomationCompatibleInterface
    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        address[] memory tokens_ = _addressProvider
            .leveragedTokenFactory()
            .allTokens();

        uint256 maxRebalances_ = _maxRebalances;
        address[] memory rebalancableTokens_ = new address[](maxRebalances_);
        uint256 rebalancableTokensCount_;
        for (uint256 i_; i_ < tokens_.length; i_++) {
            address token_ = tokens_[i_];
            if (!ILeveragedToken(token_).canRebalance()) continue;
            if (_nextAttempt[token_] > block.timestamp) continue;
            rebalancableTokens_[rebalancableTokensCount_] = token_;
            rebalancableTokensCount_++;
            if (rebalancableTokensCount_ == maxRebalances_) break;
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
