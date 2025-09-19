// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {RedBlockTreeKV} from "../src/RedBlockTreeKV.sol";
import {MappingKV} from "../src/MappingKV.sol";
import {ValueLib} from "../src/lib/Value.sol";

contract MappingGasTest is Test {
    uint256 private constant _INSERT_COUNT = 1000;
    RedBlockTreeKV public redBlockTreeKV;
    MappingKV public mappingKV;

    function setUp() public {
        redBlockTreeKV = new RedBlockTreeKV();
        mappingKV = new MappingKV();
    }

    function generateValue(uint256 value) internal pure returns (ValueLib.Value memory) {
        return ValueLib.Value({
            slot1: bytes32(uint256(value)),
            slot2: uint256(value),
            slot3: int256(value),
            slot4: bytes32(uint256(value)),
            slot5: uint256(value),
            slot6: address(uint160(value))
        });
    }

    function test_rbt_add_value() public {
        uint256 orderId = uint256(keccak256("value1"));
        uint256 gasBefore = gasleft();
        redBlockTreeKV.setValue(orderId, generateValue(1));
        uint256 gasAfter = gasleft();
        console.log("gas used", gasBefore - gasAfter);
        redBlockTreeKV.deleteValue(orderId);
        gasBefore = gasleft();
        redBlockTreeKV.setValue(orderId, generateValue(2));
        gasAfter = gasleft();
        console.log("gas used", gasBefore - gasAfter);
    }

    function test_rbt_add_value_2() public {
        // stage 1:
        console.log("add value gas usage:");

        uint256 gasBefore = gasleft();
        redBlockTreeKV.setValue(uint256(keccak256("value1")), generateValue(1));
        uint256 gasAfter = gasleft();
        console.log("insert 1 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlockTreeKV.setValue(uint256(keccak256("value2")), generateValue(2));
        gasAfter = gasleft();
        console.log("insert 2 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlockTreeKV.setValue(uint256(keccak256("value3")), generateValue(3));
        gasAfter = gasleft();
        console.log("insert 3 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlockTreeKV.setValue(uint256(keccak256("value4")), generateValue(4));
        gasAfter = gasleft();
        console.log("insert 4 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlockTreeKV.setValue(uint256(keccak256("value5")), generateValue(5));
        gasAfter = gasleft();
        console.log("insert 5 gas used", gasBefore - gasAfter);

        // stage 2:
        console.log("delete value gas usage:");

        gasBefore = gasleft();
        redBlockTreeKV.deleteValue(uint256(keccak256("value2")));
        gasAfter = gasleft();
        console.log("delete 2 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlockTreeKV.deleteValue(uint256(keccak256("value3")));
        gasAfter = gasleft();
        console.log("delete 3 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlockTreeKV.deleteValue(uint256(keccak256("value4")));
        gasAfter = gasleft();
        console.log("delete 4 gas used", gasBefore - gasAfter);

        // stage 3:
        console.log("add value gas usage:");

        gasBefore = gasleft();
        redBlockTreeKV.setValue(uint256(keccak256("value6")), generateValue(6));
        gasAfter = gasleft();
        console.log("insert 6 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlockTreeKV.setValue(uint256(keccak256("value7")), generateValue(7));
        gasAfter = gasleft();
        console.log("insert 7 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlockTreeKV.setValue(uint256(keccak256("value8")), generateValue(8));
        gasAfter = gasleft();
        console.log("insert 8 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlockTreeKV.setValue(uint256(keccak256("value9")), generateValue(9));
        gasAfter = gasleft();
        console.log("insert 9 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlockTreeKV.setValue(uint256(keccak256("value10")), generateValue(10));
        gasAfter = gasleft();
        console.log("insert 10 gas used", gasBefore - gasAfter);
    }

    /// Hot insert is gas-efficient if the slot is re-used
    /// _INSERT_COUNT 1000
    /// avgColdInsertGas 188984
    /// avgHotInsertGas 13250 <- Low!
    /// avgDeleteGas 12876
    function test_rbt_fully_insert() public {
        // init, insert 2 values and delete 1
        redBlockTreeKV.setValue(uint256(keccak256(abi.encodePacked("valueMAX"))), generateValue(UINT256_MAX));
        redBlockTreeKV.setValue(uint256(keccak256(abi.encodePacked("valueMAX-1"))), generateValue(UINT256_MAX - 1));
        redBlockTreeKV.deleteValue(uint256(keccak256(abi.encodePacked("valueMAX"))));
        uint256 gasBefore;
        uint256 gasAfter;
        uint256 totalColdInsertGas = 0;
        uint256 totalHotInsertGas = 0;
        uint256 totalDeleteGas = 0;
        // each loop: insert 2 values and delete 1, first insert is hot, second is cold
        for (uint256 i = 1; i <= _INSERT_COUNT * 2; i += 2) {
            uint256 orderId1 = uint256(keccak256(abi.encodePacked("value", i)));
            uint256 orderId2 = uint256(keccak256(abi.encodePacked("value", i + 1)));
            gasBefore = gasleft();
            redBlockTreeKV.setValue(orderId1, generateValue(i));
            gasAfter = gasleft();
            totalHotInsertGas += gasBefore - gasAfter;
            gasBefore = gasleft();
            redBlockTreeKV.setValue(orderId2, generateValue(i + 1));
            gasAfter = gasleft();
            totalColdInsertGas += gasBefore - gasAfter;
            gasBefore = gasleft();
            redBlockTreeKV.deleteValue(orderId1);
            gasAfter = gasleft();
            totalDeleteGas += gasBefore - gasAfter;
        }
        console.log("_INSERT_COUNT", _INSERT_COUNT);
        console.log("avgColdInsertGas", totalColdInsertGas / _INSERT_COUNT);
        console.log("avgHotInsertGas", totalHotInsertGas / _INSERT_COUNT);
        console.log("avgDeleteGas", totalDeleteGas / _INSERT_COUNT);
        for (uint256 i = 1; i <= _INSERT_COUNT * 2; i += 2) {
            uint256 orderId2 = uint256(keccak256(abi.encodePacked("value", i + 1)));
            ValueLib.Value memory value = redBlockTreeKV.getValue(orderId2);
            assertEq(value.slot1, bytes32(uint256(i + 1)));
            assertEq(value.slot2, uint256(i + 1));
            assertEq(value.slot3, int256(i + 1));
            assertEq(value.slot4, bytes32(uint256(i + 1)));
            assertEq(value.slot5, uint256(i + 1));
            assertEq(value.slot6, address(uint160(i + 1)));
        }
    }

    // Insert is largely gas-consuming
    /// _INSERT_COUNT 1000
    /// avgInsertGas 135350 <- High!
    /// avgDeleteGas 1529
    function test_mapping_fully_insert() public {
        // init, insert 2 values and delete 1
        mappingKV.setValue(uint256(keccak256(abi.encodePacked("valueMAX"))), generateValue(UINT256_MAX));
        mappingKV.setValue(uint256(keccak256(abi.encodePacked("valueMAX-1"))), generateValue(UINT256_MAX - 1));
        mappingKV.deleteValue(uint256(keccak256(abi.encodePacked("valueMAX"))));
        uint256 gasBefore;
        uint256 gasAfter;
        uint256 totalInsertGas = 0;
        uint256 totalDeleteGas = 0;
        // each loop: insert 2 values and delete 1, first insert is hot, second is cold
        for (uint256 i = 1; i <= _INSERT_COUNT * 2; i += 2) {
            uint256 orderId1 = uint256(keccak256(abi.encodePacked("value", i)));
            uint256 orderId2 = uint256(keccak256(abi.encodePacked("value", i + 1)));
            gasBefore = gasleft();
            mappingKV.setValue(orderId1, generateValue(i));
            gasAfter = gasleft();
            totalInsertGas += gasBefore - gasAfter;
            gasBefore = gasleft();
            mappingKV.setValue(orderId2, generateValue(i + 1));
            gasAfter = gasleft();
            totalInsertGas += gasBefore - gasAfter;
            gasBefore = gasleft();
            mappingKV.deleteValue(orderId1);
            gasAfter = gasleft();
            totalDeleteGas += gasBefore - gasAfter;
        }
        console.log("_INSERT_COUNT", _INSERT_COUNT);
        console.log("avgInsertGas", totalInsertGas / _INSERT_COUNT / 2);
        console.log("avgDeleteGas", totalDeleteGas / _INSERT_COUNT);
        for (uint256 i = 1; i <= _INSERT_COUNT * 2; i += 2) {
            uint256 orderId2 = uint256(keccak256(abi.encodePacked("value", i + 1)));
            ValueLib.Value memory value = mappingKV.getValue(orderId2);
            assertEq(value.slot1, bytes32(uint256(i + 1)));
            assertEq(value.slot2, uint256(i + 1));
            assertEq(value.slot3, int256(i + 1));
            assertEq(value.slot4, bytes32(uint256(i + 1)));
            assertEq(value.slot5, uint256(i + 1));
            assertEq(value.slot6, address(uint160(i + 1)));
        }
    }
}
