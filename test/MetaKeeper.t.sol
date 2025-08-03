// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IntegrationTest} from "./shared/IntegrationTest.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IAutomationRegistryConsumer} from "chainlink/src/v0.8/automation/interfaces/IAutomationRegistryConsumer.sol";

import {Tokens} from "../src/libraries/Tokens.sol";
import {Errors} from "../src/libraries/Errors.sol";
import {AddressKeys} from "../src/libraries/AddressKeys.sol";

import {MetaKeeper} from "../src/MetaKeeper.sol";
import {TlxUpkeepRegistry} from "../src/TlxUpkeepRegistry.sol";
import {ITlxUpkeepRegistry} from "../src/interfaces/ITlxUpkeepRegistry.sol";
import {IMetaKeeper} from "../src/interfaces/IMetaKeeper.sol";

import "../lib/forge-std/src/console.sol";

contract MetaKeeperTest is IntegrationTest {
    MetaKeeper public metaKeeper;

    TlxUpkeepRegistry public upkeepRegistry;

    uint256 constant ETH_UPKEEP_ID =
        69761711317135691618368880510486796211784454606102499205980248015108075576007;
    address constant ETH_REGISTRY_ADDRESS =
        0x696fB0d7D069cc0bb35a7c36115CE63E55cb9AA6;
    address constant ETH_UPKEEP_ADDRESS =
        0x57B76c38B583DE48ABAA3B8612B2D75A031FcD62;
    address constant ETH_OWNER_ADDRESS =
        0xf6A741259da6ee0d1A863bd847b12A6c2943Ea57;

    IAutomationRegistryConsumer public chainlinkRegistry =
        IAutomationRegistryConsumer(ETH_REGISTRY_ADDRESS);

    function setUp() public override {
        super.setUp();

        upkeepRegistry = new TlxUpkeepRegistry(address(addressProvider));
        addressProvider.updateAddress(
            AddressKeys.UPKEEP_REGISTRY,
            address(upkeepRegistry)
        );

        metaKeeper = new MetaKeeper(
            address(addressProvider),
            2,
            Tokens.LINK,
            100e18
        );

        metaKeeper.addForwarderAddress(bob);

        ITlxUpkeepRegistry.Upkeep memory upkeep = ITlxUpkeepRegistry.Upkeep(
            ETH_UPKEEP_ID,
            ETH_REGISTRY_ADDRESS,
            ETH_UPKEEP_ADDRESS
        );

        upkeepRegistry.addUpkeep(upkeep);
    }

    function testInit() public {
        (bool upkeepNeeded, bytes memory performData) = metaKeeper.checkUpkeep(
            ""
        );
        assertEq(upkeepNeeded, false);
        assertEq(performData.length, 0);
    }

    function testWithInsufficientBalance() public {
        _mintTokensFor(Tokens.LINK, address(metaKeeper), 500e18);
        uint96 currentBalance = chainlinkRegistry.getBalance(ETH_UPKEEP_ID);
        vm.mockCall(
            address(chainlinkRegistry),
            abi.encodeWithSelector(
                IAutomationRegistryConsumer.getMinBalance.selector,
                ETH_UPKEEP_ID
            ),
            abi.encode(currentBalance + 1e18)
        );
        (bool upkeepNeeded, bytes memory performData) = metaKeeper.checkUpkeep(
            ""
        );
        assertEq(upkeepNeeded, true);
        uint256[] memory keepersToTopUp = abi.decode(performData, (uint256[]));
        assertEq(keepersToTopUp.length, 1);
    }

    function testUpKeepPerformed() public {
        _mintTokensFor(Tokens.LINK, address(metaKeeper), 500e18);
        uint96 previousBalance = chainlinkRegistry.getBalance(ETH_UPKEEP_ID);
        vm.mockCall(
            address(chainlinkRegistry),
            abi.encodeWithSelector(
                IAutomationRegistryConsumer.getMinBalance.selector,
                ETH_UPKEEP_ID
            ),
            abi.encode(previousBalance + 1e18)
        );
        (bool upkeepNeeded, bytes memory performData) = metaKeeper.checkUpkeep(
            ""
        );
        assertEq(upkeepNeeded, true);
        uint256[] memory keepersToTopUp = abi.decode(performData, (uint256[]));
        assertEq(keepersToTopUp.length, 1);

        vm.prank(bob);
        metaKeeper.performUpkeep(performData);
        assertEq(
            chainlinkRegistry.getBalance(ETH_UPKEEP_ID),
            previousBalance + 100e18
        );
        assertEq(IERC20(Tokens.LINK).balanceOf(address(metaKeeper)), 400e18);
    }

    function testRevertsWithNonForwarder() public {
        _mintTokensFor(Tokens.LINK, address(metaKeeper), 500e18);
        uint96 previousBalance = chainlinkRegistry.getBalance(ETH_UPKEEP_ID);
        vm.mockCall(
            address(chainlinkRegistry),
            abi.encodeWithSelector(
                IAutomationRegistryConsumer.getMinBalance.selector,
                ETH_UPKEEP_ID
            ),
            abi.encode(previousBalance + 1e18)
        );
        (bool upkeepNeeded, bytes memory performData) = metaKeeper.checkUpkeep(
            ""
        );
        assertEq(upkeepNeeded, true);
        uint256[] memory keepersToTopUp = abi.decode(performData, (uint256[]));
        assertEq(keepersToTopUp.length, 1);

        vm.expectRevert(IMetaKeeper.NotForwarder.selector);
        metaKeeper.performUpkeep(performData);
    }

    function testRevertWithOutOfFunds() public {
        _mintTokensFor(Tokens.LINK, address(metaKeeper), 500e18);

        uint96 previousBalance = chainlinkRegistry.getBalance(ETH_UPKEEP_ID);
        vm.mockCall(
            address(chainlinkRegistry),
            abi.encodeWithSelector(
                IAutomationRegistryConsumer.getMinBalance.selector,
                ETH_UPKEEP_ID
            ),
            abi.encode(previousBalance + 1e18)
        );
        (, bytes memory performData) = metaKeeper.checkUpkeep("");
        vm.prank(address(metaKeeper));
        IERC20(Tokens.LINK).transfer(address(this), 499e18);

        vm.prank(bob);
        vm.expectRevert(IMetaKeeper.OutOfFunds.selector);
        metaKeeper.performUpkeep(performData);
    }

    function testPerformRevertsWithSufficientFunds() public {
        _mintTokensFor(Tokens.LINK, address(metaKeeper), 500e18);
        uint96 previousBalance = chainlinkRegistry.getBalance(ETH_UPKEEP_ID);
        vm.mockCall(
            address(chainlinkRegistry),
            abi.encodeWithSelector(
                IAutomationRegistryConsumer.getMinBalance.selector,
                ETH_UPKEEP_ID
            ),
            abi.encode(previousBalance + 1e18)
        );
        (bool upkeepNeeded, bytes memory performData) = metaKeeper.checkUpkeep(
            ""
        );
        assertEq(upkeepNeeded, true);
        uint256[] memory keepersToTopUp = abi.decode(performData, (uint256[]));
        assertEq(keepersToTopUp.length, 1);

        _mintTokensFor(Tokens.LINK, address(this), 500e18);
        IERC20(Tokens.LINK).approve(ETH_REGISTRY_ADDRESS, 300e18);
        chainlinkRegistry.addFunds(ETH_UPKEEP_ID, 300e18);

        vm.prank(bob);
        vm.expectRevert(IMetaKeeper.UpkeepHasSufficientFunds.selector);
        metaKeeper.performUpkeep(performData);
    }
}
