// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ValueLib} from "./lib/Value.sol";

// A simple kv example. It is gas-consuming if frequently add & remove.
contract MappingKV {
    // a mapping kv
    mapping(uint256 => ValueLib.Value) public kv;

    function setValue(uint256 key, ValueLib.Value memory value) public {
        kv[key] = value;
    }

    function getValue(uint256 key) public view returns (ValueLib.Value memory) {
        return kv[key];
    }

    function deleteValue(uint256 key) public {
        delete kv[key];
    }
}
