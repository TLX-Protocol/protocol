// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Tokens} from "../../src/libraries/Tokens.sol";
import {Contracts} from "../../src/libraries/Contracts.sol";
import {AddressKeys} from "../../src/libraries/AddressKeys.sol";

import {ChainlinkOracle} from "../../src/ChainlinkOracle.sol";
import {MockOracle} from "../../src/testing/MockOracle.sol";
import {LeveragedTokenFactory} from "../../src/LeveragedTokenFactory.sol";
import {AddressProvider} from "../../src/AddressProvider.sol";
import {PositionManagerFactory} from "../../src/PositionManagerFactory.sol";
import {MockDerivativesHandler} from "../../src/testing/MockDerivativesHandler.sol";

contract IntegrationTest is Test {
    using stdStorage for StdStorage;

    ChainlinkOracle public chainlinkOracle;
    MockOracle public mockOracle;
    LeveragedTokenFactory public leveragedTokenFactory;
    AddressProvider public addressProvider;
    PositionManagerFactory public positionManagerFactory;
    MockDerivativesHandler public mockDerivativesHandler;

    constructor() {
        vm.selectFork(vm.createFork(vm.envString("RPC"), 17_491_596));

        // AddressProvider Setup
        addressProvider = new AddressProvider();

        // Chainlink Oracle Setup
        chainlinkOracle = new ChainlinkOracle(Contracts.ETH_USD_ORACLE);
        chainlinkOracle.setUsdOracle(Tokens.UNI, Contracts.UNI_USD_ORACLE);
        chainlinkOracle.setUsdOracle(address(0), Contracts.ETH_USD_ORACLE);
        chainlinkOracle.setUsdOracle(Tokens.USDC, Contracts.USDC_USD_ORACLE);
        chainlinkOracle.setEthOracle(Tokens.WBTC, Contracts.WBTC_ETH_ORACLE);
        addressProvider.updateAddress(
            AddressKeys.ORACLE,
            address(chainlinkOracle)
        );

        // Mock Oracle Setup
        mockOracle = new MockOracle();
        uint256 uniPrice_ = chainlinkOracle.getUsdPrice(Tokens.UNI);
        mockOracle.setPrice(Tokens.UNI, uniPrice_);
        uint256 ethPrice_ = chainlinkOracle.getUsdPrice(address(0));
        mockOracle.setPrice(address(0), ethPrice_);
        uint256 usdcPrice_ = chainlinkOracle.getUsdPrice(Tokens.USDC);
        mockOracle.setPrice(Tokens.USDC, usdcPrice_);

        // LeveragedTokenFactory Setup
        leveragedTokenFactory = new LeveragedTokenFactory(
            address(addressProvider)
        );
        addressProvider.updateAddress(
            AddressKeys.LEVERAGED_TOKEN_FACTORY,
            address(leveragedTokenFactory)
        );

        // PositionManagerFactory Setup
        positionManagerFactory = new PositionManagerFactory(
            address(addressProvider)
        );
        addressProvider.updateAddress(
            AddressKeys.POSITION_MANAGER_FACTORY,
            address(positionManagerFactory)
        );

        // MockDerivativesHandler Setup
        mockDerivativesHandler = new MockDerivativesHandler(
            address(addressProvider),
            0.2e18
        );
        _mintTokensFor(
            Tokens.USDC,
            address(mockDerivativesHandler.approveAddress()),
            10_000_000e6
        );
        addressProvider.updateAddress(
            AddressKeys.DERIVATIVES_HANDLER,
            address(mockDerivativesHandler)
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
