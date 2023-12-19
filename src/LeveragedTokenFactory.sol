// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {Errors} from "./libraries/Errors.sol";

import {ILeveragedTokenFactory} from "./interfaces/ILeveragedTokenFactory.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {LeveragedToken} from "./LeveragedToken.sol";

contract LeveragedTokenFactory is ILeveragedTokenFactory, Ownable {
    IAddressProvider internal immutable _addressProvider;
    uint256 internal immutable _maxLeverage;

    address[] internal _allTokens;
    address[] internal _longTokens;
    address[] internal _shortTokens;
    mapping(string => address[]) internal _allTargetTokens;
    mapping(string => address[]) internal _longTargetTokens;
    mapping(string => address[]) internal _shortTargetTokens;
    mapping(string => mapping(uint256 => mapping(bool => address)))
        internal _tokens;

    mapping(address => address) public override pair;
    mapping(address => bool) public override isLeveragedToken;

    constructor(address addressProvider_, uint256 maxLeverage_) {
        _addressProvider = IAddressProvider(addressProvider_);
        _maxLeverage = maxLeverage_;
    }

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
        if (targetLeverage_ > _maxLeverage) revert MaxLeverage();
        if (tokenExists(targetAsset_, targetLeverage_, true))
            revert Errors.AlreadyExists();
        if (!_addressProvider.synthetixHandler().isAssetSupported(targetAsset_))
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

    function allTokens() external view override returns (address[] memory) {
        return _allTokens;
    }

    function longTokens() external view override returns (address[] memory) {
        return _longTokens;
    }

    function shortTokens() external view override returns (address[] memory) {
        return _shortTokens;
    }

    function allTokens(
        string calldata targetAsset_
    ) external view override returns (address[] memory) {
        return _allTargetTokens[targetAsset_];
    }

    function longTokens(
        string calldata targetAsset_
    ) external view override returns (address[] memory) {
        return _longTargetTokens[targetAsset_];
    }

    function shortTokens(
        string calldata targetAsset_
    ) external view override returns (address[] memory) {
        return _shortTargetTokens[targetAsset_];
    }

    function token(
        string calldata targetAsset_,
        uint256 targetLeverage_,
        bool isLong_
    ) external view override returns (address) {
        return _tokens[targetAsset_][targetLeverage_][isLong_];
    }

    function tokenExists(
        string calldata targetAsset_,
        uint256 targetLeverage_,
        bool isLong_
    ) public view override returns (bool) {
        return _tokens[targetAsset_][targetLeverage_][isLong_] != address(0);
    }

    function _deployToken(
        string calldata targetAsset_,
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
        string calldata targetAsset_,
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
        string calldata targetAsset_,
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
