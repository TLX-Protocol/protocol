// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {Errors} from "../libraries/Errors.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {ILeveragedToken} from "../interfaces/ILeveragedToken.sol";
import {IPolManager} from "../interfaces/IPolManager.sol";

contract PolManager is Ownable, IPolManager {
    IAddressProvider public immutable addressProvider;

    constructor(
        address initialOwner_,
        IAddressProvider addressProvider_
    ) Ownable(initialOwner_) {
        addressProvider = addressProvider_;
    }

    function redeemTokens(
        TokenToRedeem[] calldata tokensToRedeem_,
        uint256 minAmountOut_
    ) external override onlyOwner returns (uint256) {
        address pol_ = addressProvider.pol();
        IERC20 baseAsset_ = addressProvider.baseAsset();
        uint256 totalReceived_;

        for (uint256 i; i < tokensToRedeem_.length; i++) {
            totalReceived_ += _redeem(tokensToRedeem_[i]);
        }
        if (totalReceived_ < minAmountOut_) revert Errors.InsufficientAmount();
        baseAsset_.transfer(pol_, totalReceived_);
        return totalReceived_;
    }

    function recoverTokens(
        address tokenAddress_,
        uint256 amount_
    ) external onlyOwner {
        IERC20(tokenAddress_).transfer(owner(), amount_);
    }

    function _redeem(
        TokenToRedeem memory tokenToRedeem_
    ) internal returns (uint256) {
        IERC20(tokenToRedeem_.tokenAddress).transferFrom(
            addressProvider.pol(),
            address(this),
            tokenToRedeem_.amount
        );
        return
            ILeveragedToken(tokenToRedeem_.tokenAddress).redeem(
                tokenToRedeem_.amount,
                0
            );
    }
}
