// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Config} from "./Config.sol";
import {AddressKeys} from "./AddressKeys.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IRewardsStreaming} from "../interfaces/IRewardsStreaming.sol";

library InitialMint {
    /**
     * @notice Action to be executed by the TlxToken contract after minting the token.
     */
    struct Action {
        address target;
        bytes data;
    }

    /**
     * @notice Amount to mint to `receiver`
     * Can execute arbitrary actions through `actions` if needed
     */
    struct Data {
        address receiver;
        uint256 amount;
        Action[] actions;
    }

    function getData(
        IAddressProvider addressProvider_
    ) internal view returns (Data[] memory) {
        Data[] memory mintData_ = new Data[](5);

        Action[] memory genesisLockerActions = new Action[](2);
        genesisLockerActions[0] = Action({
            target: addressProvider_.addressOf(AddressKeys.TLX),
            data: abi.encodeWithSelector(
                IERC20.approve.selector,
                addressProvider_.addressOf(AddressKeys.GENESIS_LOCKER),
                Config.STREAMED_AIRDROP_AMOUNT
            )
        });
        genesisLockerActions[1] = Action({
            target: addressProvider_.addressOf(AddressKeys.GENESIS_LOCKER),
            data: abi.encodeWithSelector(
                IRewardsStreaming.donateRewards.selector,
                Config.STREAMED_AIRDROP_AMOUNT
            )
        });

        mintData_[0] = Data({
            receiver: Config.AMM_DISTRIBUTOR,
            amount: Config.AMM_AMOUNT,
            actions: new Action[](0)
        });
        mintData_[1] = Data({
            receiver: address(addressProvider_.airdrop()),
            amount: Config.DIRECT_AIRDROP_AMOUNT,
            actions: new Action[](0)
        });
        mintData_[2] = Data({
            receiver: addressProvider_.addressOf(AddressKeys.TLX),
            amount: Config.STREAMED_AIRDROP_AMOUNT,
            actions: genesisLockerActions
        });
        mintData_[3] = Data({
            receiver: addressProvider_.addressOf(AddressKeys.VESTING),
            amount: Config.VESTING_AMOUNT,
            actions: new Action[](0)
        });
        mintData_[4] = Data({
            receiver: addressProvider_.addressOf(AddressKeys.BONDING),
            amount: Config.BONDING_AMOUNT,
            actions: new Action[](0)
        });

        return mintData_;
    }
}
