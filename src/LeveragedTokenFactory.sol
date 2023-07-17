// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Tokens} from "./libraries/Tokens.sol";

import {ILeveragedTokenFactory} from "./interfaces/ILeveragedTokenFactory.sol";
import {ILeveragedToken} from "./interfaces/ILeveragedToken.sol";
import {IAddressProvider} from "./interfaces/IAddressProvider.sol";
import {IPositionManagerFactory} from "./interfaces/IPositionManagerFactory.sol";
import {LeveragedToken} from "./LeveragedToken.sol";

contract LeveragedTokenFactory is ILeveragedTokenFactory, Ownable {
    address internal immutable _addressProvider;
    address[] internal _allTokens;
    address[] internal _longTokens;
    address[] internal _shortTokens;
    mapping(address => address[]) internal _allTargetTokens;
    mapping(address => address[]) internal _longTargetTokens;
    mapping(address => address[]) internal _shortTargetTokens;
    mapping(address => mapping(uint256 => mapping(bool => address)))
        internal _tokens;

    mapping(address => address) public override pair;
    mapping(address => bool) public override isLeveragedToken;

    constructor(address addressProvider_) {
        _addressProvider = addressProvider_;
    }

    function createLeveragedTokens(
        address targetAsset_,
        uint256 targetLeverage_
    )
        external
        override
        onlyOwner
        returns (address longToken, address shortToken)
    {
        // Checks
        if (targetAsset_ == address(0)) revert ZeroAddress();
        if (targetLeverage_ == 0) revert ZeroLeverage();
        if (targetLeverage_ > 100e3) revert MaxLeverage();
        if (tokenExists(targetAsset_, targetLeverage_, true))
            revert TokenExists();
        IPositionManagerFactory positionManagerFactory_ = IPositionManagerFactory(
                IAddressProvider(_addressProvider).positionManagerFactory()
            );
        address positionManager_ = positionManagerFactory_.positionManager(
            targetAsset_
        );
        if (positionManager_ == address(0)) revert NoPositionManager();

        // Deploying tokens
        longToken = _deployToken(
            positionManager_,
            targetAsset_,
            targetLeverage_,
            true
        );
        shortToken = _deployToken(
            positionManager_,
            targetAsset_,
            targetLeverage_,
            false
        );

        // Setting pairs
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
        address targetAsset_
    ) external view override returns (address[] memory) {
        return _allTargetTokens[targetAsset_];
    }

    function longTokens(
        address targetAsset_
    ) external view override returns (address[] memory) {
        return _longTargetTokens[targetAsset_];
    }

    function shortTokens(
        address targetAsset_
    ) external view override returns (address[] memory) {
        return _shortTargetTokens[targetAsset_];
    }

    function token(
        address targetAsset_,
        uint256 targetLeverage_,
        bool isLong_
    ) external view override returns (address) {
        return _tokens[targetAsset_][targetLeverage_][isLong_];
    }

    function tokenExists(
        address targetAsset_,
        uint256 targetLeverage_,
        bool isLong_
    ) public view override returns (bool) {
        return _tokens[targetAsset_][targetLeverage_][isLong_] != address(0);
    }

    function _deployToken(
        address positionManager_,
        address targetAsset_,
        uint256 targetLeverage_,
        bool isLong_
    ) internal returns (address) {
        address token_ = address(
            new LeveragedToken(
                _getName(targetAsset_, targetLeverage_, isLong_),
                _getSymbol(targetAsset_, targetLeverage_, isLong_),
                Tokens.USDC,
                targetAsset_,
                targetLeverage_,
                isLong_,
                positionManager_
            )
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
        address targetAsset_,
        uint256 targetLeverage_,
        bool isLong_
    ) internal view returns (string memory) {
        string memory direction_ = isLong_ ? "Long" : "Short";
        string memory symbol_ = IERC20Metadata(targetAsset_).symbol();
        string memory leverage_ = _getLeverageString(targetLeverage_);
        return
            string(abi.encodePacked(symbol_, " ", leverage_, "x ", direction_));
    }

    function _getSymbol(
        address targetAsset_,
        uint256 targetLeverage_,
        bool isLong_
    ) internal view returns (string memory) {
        string memory direction_ = isLong_ ? "L" : "S";
        string memory symbol_ = IERC20Metadata(targetAsset_).symbol();
        string memory leverage_ = _getLeverageString(targetLeverage_);
        return string(abi.encodePacked(symbol_, leverage_, direction_));
    }

    function _getLeverageString(
        uint256 targetLeverage_
    ) internal pure returns (string memory) {
        uint256 wholeNumber_ = targetLeverage_ / 1e2;
        uint256 partOfWhole_ = targetLeverage_ % 1e2;
        string memory wholeNumberString_ = Strings.toString(wholeNumber_);
        if (partOfWhole_ == 0) return wholeNumberString_;
        string memory partOfWholeString_ = Strings.toString(partOfWhole_);
        return
            string(
                abi.encodePacked(wholeNumberString_, ".", partOfWholeString_)
            );
    }
}
