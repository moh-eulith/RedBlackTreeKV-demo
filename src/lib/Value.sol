// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ValueLib {
    uint256 public constant SLOTS_PER_POSITION = 6;

    struct Value {
        bytes32 slot1;
        uint256 slot2;
        int256 slot3;
        bytes32 slot4;
        uint256 slot5;
        address slot6;
    }
}
