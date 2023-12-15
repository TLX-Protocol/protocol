// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {DeploymentScript} from "./shared/DeploymentScript.s.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {Tokens} from "../../src/libraries/Tokens.sol";
import {Contracts} from "../../src/libraries/Contracts.sol";
import {AddressKeys} from "../../src/libraries/AddressKeys.sol";
import {ParameterKeys} from "../../src/libraries/ParameterKeys.sol";
import {Config} from "../../src/libraries/Config.sol";
import {Symbols} from "../../src/libraries/Symbols.sol";

import {IVesting} from "../../src/interfaces/IVesting.sol";
import {IPerpsV2MarketData} from "../../src/interfaces/synthetix/IPerpsV2MarketData.sol";
import {IPerpsV2MarketConsolidated} from "../../src/interfaces/synthetix/IPerpsV2MarketConsolidated.sol";
import {IAddressProvider} from "../../src/interfaces/IAddressProvider.sol";

import {LeveragedTokenFactory} from "../../src/LeveragedTokenFactory.sol";
import {AddressProvider} from "../../src/AddressProvider.sol";
import {ParameterProvider} from "../../src/ParameterProvider.sol";
import {Referrals} from "../../src/Referrals.sol";
import {TlxToken} from "../../src/TlxToken.sol";
import {Airdrop} from "../../src/Airdrop.sol";
import {Locker} from "../../src/Locker.sol";
import {Bonding} from "../../src/Bonding.sol";
import {Vesting} from "../../src/Vesting.sol";
import {SynthetixHandler} from "../../src/SynthetixHandler.sol";

import {Base64} from "../../src/testing/Base64.sol";

contract ProtocolDeployment is DeploymentScript {
    function _run() internal override {
        // Getting deployed contracts
        IAddressProvider addressProvider = IAddressProvider(
            _getDeployedAddress("AddressProvider")
        );

        // Deploying Leveraged Token Factory
        LeveragedTokenFactory leveragedTokenFactory = new LeveragedTokenFactory(
            address(addressProvider),
            Config.MAX_LEVERAGE
        );
        _deployedAddress(
            "LeveragedTokenFactory",
            address(leveragedTokenFactory)
        );
        addressProvider.updateAddress(
            AddressKeys.LEVERAGED_TOKEN_FACTORY,
            address(leveragedTokenFactory)
        );
        revert("meow");
    }
}
