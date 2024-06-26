// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

library Errors {
    error NotAuthorized();
    error AlreadyExists();
    error DoesNotExist();
    error ZeroAddress();
    error SameAsCurrent();
    error InvalidAddress();
    error InsufficientAmount();
    error NotLeveragedToken();
}
