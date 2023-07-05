// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Tokens} from "../../src/libraries/Tokens.sol";
import {Contracts} from "../../src/libraries/Contracts.sol";

import {Oracle} from "../../src/Oracle.sol";
import {LeveragedTokenFactory} from "../../src/LeveragedTokenFactory.sol";
import {AddressProvider} from "../../src/AddressProvider.sol";
import {GmxDerivativesHandler} from "../../src/GmxDerivativesHandler.sol";
import {PositionManagerFactory} from "../../src/PositionManagerFactory.sol";

contract IntegrationTest is Test {
    using stdStorage for StdStorage;

    Oracle public oracle;
    LeveragedTokenFactory public leveragedTokenFactory;
    AddressProvider public addressProvider;
    GmxDerivativesHandler public derivativesHandler;
    PositionManagerFactory public positionManagerFactory;

    constructor() {
        vm.selectFork(vm.createFork(vm.envString("RPC"), 17_491_596));

        // AddressProvider Setup
        addressProvider = new AddressProvider();

        // Oracle Setup
        oracle = new Oracle(Contracts.ETH_USD_ORACLE);
        oracle.setUsdOracle(Tokens.UNI, Contracts.UNI_USD_ORACLE);

        // LeveragedTokenFactory Setup
        leveragedTokenFactory = new LeveragedTokenFactory(
            address(addressProvider)
        );

        // PositionManagerFactory Setup
        positionManagerFactory = new PositionManagerFactory();

        // DerivativesHandler Setup
        derivativesHandler = new GmxDerivativesHandler(
            address(addressProvider),
            Contracts.GMX_POSITION_ROUTER,
            Contracts.GMX_ROUTER,
            Tokens.USDC
        );

        // AddressProvider Initialization
        addressProvider.initialize(
            address(leveragedTokenFactory),
            address(positionManagerFactory),
            address(oracle)
        );
    }

    function _mintTokensFor(
        address token_,
        address account_,
        uint256 amount_
    ) internal {
        stdstore
            .target(token_)
            .sig(IERC20(token_).balanceOf.selector)
            .with_key(account_)
            .checked_write(amount_);
    }
}
