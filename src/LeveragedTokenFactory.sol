// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {TlxOwnable} from "./utils/TlxOwnable.sol";

import {Errors} from "./libraries/Errors.sol";

import {ILeveragedTokenFactory} from "./interfaces/ILeveragedTokenFactory.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {LeveragedToken} from "./LeveragedToken.sol";
import {ISynthetixHandler} from "./interfaces/ISynthetixHandler.sol";

contract LeveragedTokenFactory is ILeveragedTokenFactory, TlxOwnable {
    IAddressProvider internal immutable _addressProvider;

    address[] internal _allTokens;
    address[] internal _longTokens;
    address[] internal _shortTokens;
    mapping(string => address[]) internal _allTargetTokens;
    mapping(string => address[]) internal _longTargetTokens;
    mapping(string => address[]) internal _shortTargetTokens;
    mapping(string => mapping(uint256 => mapping(bool => address)))
        internal _tokens;

    /// @inheritdoc ILeveragedTokenFactory
    mapping(address => address) public override pair;
    /// @inheritdoc ILeveragedTokenFactory
    mapping(address => bool) public override isLeveragedToken;

    constructor(address addressProvider_) TlxOwnable(addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
    }

    /// @inheritdoc ILeveragedTokenFactory
    function createLeveragedTokens(
        string calldata targetAsset_,
        uint256 targetLeverage_,
        uint256 rebalanceThreshold_
    )
        external
        override
        onlyOwner
        returns (address longToken, address shortToken)
    {
        // Checks
        uint256 leveragePartOfWhole_ = targetLeverage_ % 1e18;
        uint256 truncatedToTwoDecimals_ = (leveragePartOfWhole_ / 1e16) * 1e16;
        bool hasTwoDecimals_ = leveragePartOfWhole_ == truncatedToTwoDecimals_;
        if (!hasTwoDecimals_) revert MaxOfTwoDecimals();
        if (targetLeverage_ == 0) revert ZeroLeverage();
        ISynthetixHandler synthetixHandler_ = _addressProvider
            .synthetixHandler();
        uint256 maxLeverage_ = synthetixHandler_.maxLeverage(targetAsset_) / 2;
        if (targetLeverage_ > maxLeverage_) revert MaxLeverage();
        if (tokenExists(targetAsset_, targetLeverage_, true))
            revert Errors.AlreadyExists();
        if (!synthetixHandler_.isAssetSupported(targetAsset_))
            revert AssetNotSupported();

        // Deploying tokens
        longToken = _deployToken(
            targetAsset_,
            targetLeverage_,
            true,
            rebalanceThreshold_
        );
        shortToken = _deployToken(
            targetAsset_,
            targetLeverage_,
            false,
            rebalanceThreshold_
        );

        // Setting storage
        pair[longToken] = shortToken;
        pair[shortToken] = longToken;
    }

    /// @inheritdoc ILeveragedTokenFactory
    function redeployInactiveToken(
        address tokenAddress_
    ) external onlyOwner returns (address) {
        if (!isLeveragedToken[tokenAddress_]) revert Errors.NotLeveragedToken();
        ILeveragedToken leveragedToken_ = ILeveragedToken(tokenAddress_);
        if (leveragedToken_.isActive()) revert NotInactive();
        address pair_ = pair[tokenAddress_];

        address newToken_ = _deployToken(
            leveragedToken_.targetAsset(),
            leveragedToken_.targetLeverage(),
            leveragedToken_.isLong(),
            leveragedToken_.rebalanceThreshold()
        );

        pair[pair_] = newToken_;
        pair[newToken_] = pair_;
        delete isLeveragedToken[tokenAddress_];

        return newToken_;
    }

    /// @inheritdoc ILeveragedTokenFactory
    function allTokens() external view override returns (address[] memory) {
        return _allTokens;
    }

    /// @inheritdoc ILeveragedTokenFactory
    function longTokens() external view override returns (address[] memory) {
        return _longTokens;
    }

    /// @inheritdoc ILeveragedTokenFactory
    function shortTokens() external view override returns (address[] memory) {
        return _shortTokens;
    }

    /// @inheritdoc ILeveragedTokenFactory
    function allTokens(
        string calldata targetAsset_
    ) external view override returns (address[] memory) {
        return _allTargetTokens[targetAsset_];
    }

    /// @inheritdoc ILeveragedTokenFactory
    function longTokens(
        string calldata targetAsset_
    ) external view override returns (address[] memory) {
        return _longTargetTokens[targetAsset_];
    }

    /// @inheritdoc ILeveragedTokenFactory
    function shortTokens(
        string calldata targetAsset_
    ) external view override returns (address[] memory) {
        return _shortTargetTokens[targetAsset_];
    }

    /// @inheritdoc ILeveragedTokenFactory
    function token(
        string calldata targetAsset_,
        uint256 targetLeverage_,
        bool isLong_
    ) external view override returns (address) {
        return _tokens[targetAsset_][targetLeverage_][isLong_];
    }

    /// @inheritdoc ILeveragedTokenFactory
    function tokenExists(
        string calldata targetAsset_,
        uint256 targetLeverage_,
        bool isLong_
    ) public view override returns (bool) {
        return _tokens[targetAsset_][targetLeverage_][isLong_] != address(0);
    }

    function _deployToken(
        string memory targetAsset_,
        uint256 targetLeverage_,
        bool isLong_,
        uint256 rebalanceThreshold_
    ) internal returns (address) {
        address token_ = address(
            new LeveragedToken(
                _getName(targetAsset_, targetLeverage_, isLong_),
                _getSymbol(targetAsset_, targetLeverage_, isLong_),
                targetAsset_,
                targetLeverage_,
                isLong_,
                address(_addressProvider)
            )
        );
        _addressProvider.parameterProvider().updateRebalanceThreshold(
            token_,
            rebalanceThreshold_
        );
        isLeveragedToken[token_] = true;
        _tokens[targetAsset_][targetLeverage_][isLong_] = token_;
        _allTokens.push(token_);
        _allTargetTokens[targetAsset_].push(token_);
        if (isLong_) {
            _longTokens.push(token_);
            _longTargetTokens[targetAsset_].push(token_);
        } else {
            _shortTokens.push(token_);
            _shortTargetTokens[targetAsset_].push(token_);
        }
        emit NewLeveragedToken(token_);
        return token_;
    }

    function _getName(
        string memory targetAsset_,
        uint256 targetLeverage_,
        bool isLong_
    ) internal pure returns (string memory) {
        string memory direction_ = isLong_ ? "Long" : "Short";
        string memory leverage_ = _getLeverageString(targetLeverage_);
        return
            string(
                abi.encodePacked(targetAsset_, " ", leverage_, "x ", direction_)
            );
    }

    function _getSymbol(
        string memory targetAsset_,
        uint256 targetLeverage_,
        bool isLong_
    ) internal pure returns (string memory) {
        string memory direction_ = isLong_ ? "L" : "S";
        string memory leverage_ = _getLeverageString(targetLeverage_);
        return string(abi.encodePacked(targetAsset_, leverage_, direction_));
    }

    function _getLeverageString(
        uint256 targetLeverage_
    ) internal pure returns (string memory) {
        uint256 wholeNumber_ = targetLeverage_ / 1e18;
        uint256 partOfWhole_ = (targetLeverage_ % 1e18) / 1e16;
        string memory wholeNumberString_ = Strings.toString(wholeNumber_);
        if (partOfWhole_ == 0) return wholeNumberString_;
        string memory partOfWholeString_ = Strings.toString(partOfWhole_);
        return
            string(
                abi.encodePacked(wholeNumberString_, ".", partOfWholeString_)
            );
    }
}
