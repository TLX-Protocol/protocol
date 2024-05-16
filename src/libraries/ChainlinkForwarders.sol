// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

library ChainlinkForwarders {
    function forwarders() internal pure returns (address[] memory forwarders_) {
        forwarders_ = new address[](5);
        forwarders_[0] = 0x05D2BFD1af4F17B29dD8760727162bf1A9fDAe40; // ETH
        forwarders_[1] = 0x7E44677f6E808CF9FFB1178e88A62083B09d9535; // BTC
        forwarders_[2] = 0x92EF69229f6D8fd6EFeCe8a93e3Ab1EC5BF5415e; // OP
        forwarders_[3] = 0x8D981Ddc94b26a1Aaaf37993661A49c071a791FC; // LINK
        forwarders_[4] = 0xB1666242830b7242C14AB61E8978594B44e57eFb; // SOL
    }
}
