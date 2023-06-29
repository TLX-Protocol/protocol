// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {Tokens} from "../../src/libraries/Tokens.sol";
import {Contracts} from "../../src/libraries/Contracts.sol";

import {Oracle} from "../../src/Oracle.sol";
import {LeveragedTokenFactory} from "../../src/LeveragedTokenFactory.sol";
import {AddressProvider} from "../../src/AddressProvider.sol";
import {GmxDerivativesHandler} from "../../src/GmxDerivativesHandler.sol";

contract IntegrationTest is Test {
    Oracle public oracle;
    LeveragedTokenFactory public leveragedTokenFactory;
    AddressProvider public addressProvider;
    GmxDerivativesHandler public derivativesHandler;

    constructor() {
        vm.selectFork(vm.createFork(vm.envString("RPC"), 17_491_596));

        // Oracle Setup
        oracle = new Oracle(Contracts.ETH_USD_ORACLE);
        oracle.setUsdOracle(Tokens.UNI, Contracts.UNI_USD_ORACLE);

        // LeveragedTokenFactory Setup
        leveragedTokenFactory = new LeveragedTokenFactory();

        // AddressProvider Setup
        addressProvider = new AddressProvider(
            address(leveragedTokenFactory),
            address(oracle)
        );

        // DerivativesHandler Setup
        derivativesHandler = new GmxDerivativesHandler(
            address(addressProvider),
            Contracts.GMX_POSITION_ROUTER,
            Contracts.GMX_ROUTER,
            Tokens.USDC
        );
    }
}
