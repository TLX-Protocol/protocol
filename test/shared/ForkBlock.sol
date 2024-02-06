// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

// This value is moved to a separate contract so we can hash this file to determine when the fork block has changed
// This is used in our CI cache so we know when we need to refresh the RPC cache
library ForkBlock {
    uint256 public constant NUMBER = 113_220_646;
}
