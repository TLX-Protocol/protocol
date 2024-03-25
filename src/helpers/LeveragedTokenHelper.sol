// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {ILeveragedToken} from "../interfaces/ILeveragedToken.sol";
import {ISynthetixHandler} from "../interfaces/ISynthetixHandler.sol";

contract LeveragedTokenHelper {
    struct LeveragedTokenData {
        address addr;
        string name;
        string symbol;
        uint256 totalSupply;
        string targetAsset;
        uint256 targetLeverage;
        bool isLong;
        bool isActive;
        uint256 rebalanceThreshold;
        uint256 exchangeRate;
        bool canRebalance;
        bool hasPendingLeverageUpdate;
        uint256 remainingMargin;
        uint256 leverage;
        uint256 assetPrice;
    }

    IAddressProvider internal immutable _addressProvider;

    constructor(address addressProvider_) {
        _addressProvider = IAddressProvider(addressProvider_);
    }

    function leveragedTokenData()
        public
        view
        returns (LeveragedTokenData[] memory)
    {
        address[] memory leveragedTokenAddresses_ = _addressProvider
            .leveragedTokenFactory()
            .allTokens();
        LeveragedTokenData[]
            memory leveragedTokenData_ = new LeveragedTokenData[](
                leveragedTokenAddresses_.length
            );
        ISynthetixHandler synthetixHandler_ = ISynthetixHandler(
            _addressProvider.synthetixHandler()
        );
        for (uint256 i_; i_ < leveragedTokenAddresses_.length; i_++) {
            ILeveragedToken leveragedToken_ = ILeveragedToken(
                leveragedTokenAddresses_[i_]
            );
            string memory targetAsset_ = leveragedToken_.targetAsset();
            address market_ = synthetixHandler_.market(targetAsset_);
            uint256 remainingMargin_ = synthetixHandler_.remainingMargin(
                market_,
                address(leveragedToken_)
            );
            uint256 leverage_;
            if (remainingMargin_ != 0) {
                leverage_ = synthetixHandler_.leverage(
                    market_,
                    address(leveragedToken_)
                );
            }
            leveragedTokenData_[i_] = LeveragedTokenData({
                addr: address(leveragedToken_),
                name: leveragedToken_.name(),
                symbol: leveragedToken_.symbol(),
                totalSupply: leveragedToken_.totalSupply(),
                targetAsset: targetAsset_,
                targetLeverage: leveragedToken_.targetLeverage(),
                isLong: leveragedToken_.isLong(),
                isActive: leveragedToken_.isActive(),
                rebalanceThreshold: leveragedToken_.rebalanceThreshold(),
                exchangeRate: leveragedToken_.exchangeRate(),
                canRebalance: leveragedToken_.canRebalance(),
                hasPendingLeverageUpdate: synthetixHandler_
                    .hasPendingLeverageUpdate(
                        market_,
                        address(leveragedToken_)
                    ),
                remainingMargin: remainingMargin_,
                leverage: leverage_,
                assetPrice: synthetixHandler_.assetPrice(market_)
            });
        }
        return leveragedTokenData_;
    }
}
