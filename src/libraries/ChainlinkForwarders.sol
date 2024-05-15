// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

library ChainlinkForwarders {
    function forwarders() internal pure returns (address[] memory forwarders_) {
        forwarders_ = new address[](5);
        forwarders_[0] = address(0);
        forwarders_[1] = address(0);
        forwarders_[2] = address(0);
        forwarders_[3] = address(0);
        forwarders_[4] = address(0);
    }
}
