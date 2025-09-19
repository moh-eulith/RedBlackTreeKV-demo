// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {RedBlockTreeKV} from "../src/RedBlockTreeKV.sol";
import {ValueLib} from "../src/lib/Value.sol";
import {RedBlackTreeLib} from "../src/lib/RedBlackTreeLib.sol";

contract RedBlockTreeKVTest is Test {
    RedBlockTreeKV public redBlockTreeKV;

    function setUp() public {
        redBlockTreeKV = new RedBlockTreeKV();
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

    function test_setValue_and_getValue() public {
        uint256 key = 1;
        ValueLib.Value memory expectedValue = generateValue(100);

        redBlockTreeKV.setValue(key, expectedValue);
        ValueLib.Value memory actualValue = redBlockTreeKV.getValue(key);

        assertEq(actualValue.slot1, expectedValue.slot1);
        assertEq(actualValue.slot2, expectedValue.slot2);
        assertEq(actualValue.slot3, expectedValue.slot3);
        assertEq(actualValue.slot4, expectedValue.slot4);
        assertEq(actualValue.slot5, expectedValue.slot5);
        assertEq(actualValue.slot6, expectedValue.slot6);
    }

    function test_setValue_overwrite() public {
        uint256 key = 1;
        ValueLib.Value memory value1 = generateValue(100);
        ValueLib.Value memory value2 = generateValue(200);

        redBlockTreeKV.setValue(key, value1);
        vm.expectRevert(RedBlackTreeLib.ValueAlreadyExists.selector);
        redBlockTreeKV.setValue(key, value2);
    }

    function test_deleteValue() public {
        uint256 key = 1;
        ValueLib.Value memory value = generateValue(100);

        redBlockTreeKV.setValue(key, value);
        redBlockTreeKV.deleteValue(key);

        uint256[] memory values = redBlockTreeKV.values();
        assertEq(values.length, 0);
    }

    function test_multiple_values() public {
        uint256 key1 = 1;
        uint256 key2 = 2;
        uint256 key3 = 3;

        ValueLib.Value memory value1 = generateValue(100);
        ValueLib.Value memory value2 = generateValue(200);
        ValueLib.Value memory value3 = generateValue(300);

        redBlockTreeKV.setValue(key1, value1);
        redBlockTreeKV.setValue(key2, value2);
        redBlockTreeKV.setValue(key3, value3);

        ValueLib.Value memory actualValue1 = redBlockTreeKV.getValue(key1);
        ValueLib.Value memory actualValue2 = redBlockTreeKV.getValue(key2);
        ValueLib.Value memory actualValue3 = redBlockTreeKV.getValue(key3);

        assertEq(actualValue1.slot2, 100);
        assertEq(actualValue2.slot2, 200);
        assertEq(actualValue3.slot2, 300);

        uint256[] memory values = redBlockTreeKV.values();
        assertEq(values.length, 3);
    }

    function test_delete_middle_value() public {
        uint256 key1 = 1;
        uint256 key2 = 2;
        uint256 key3 = 3;

        ValueLib.Value memory value1 = generateValue(100);
        ValueLib.Value memory value2 = generateValue(200);
        ValueLib.Value memory value3 = generateValue(300);

        redBlockTreeKV.setValue(key1, value1);
        redBlockTreeKV.setValue(key2, value2);
        redBlockTreeKV.setValue(key3, value3);

        redBlockTreeKV.deleteValue(key2);

        ValueLib.Value memory actualValue1 = redBlockTreeKV.getValue(key1);
        ValueLib.Value memory actualValue3 = redBlockTreeKV.getValue(key3);

        assertEq(actualValue1.slot2, 100);
        assertEq(actualValue3.slot2, 300);

        uint256[] memory values = redBlockTreeKV.values();
        assertEq(values.length, 2);
    }

    function test_values_empty() public view {
        uint256[] memory values = redBlockTreeKV.values();
        assertEq(values.length, 0);
    }

    function test_values_ordering() public {
        uint256[] memory keys = new uint256[](5);
        keys[0] = 50;
        keys[1] = 30;
        keys[2] = 70;
        keys[3] = 20;
        keys[4] = 60;

        for (uint256 i = 0; i < keys.length; i++) {
            redBlockTreeKV.setValue(keys[i], generateValue(keys[i]));
        }

        uint256[] memory values = redBlockTreeKV.values();
        assertEq(values.length, 5);

        for (uint256 i = 0; i < values.length - 1; i++) {
            assertLt(values[i], values[i + 1]);
        }
    }

    function test_edge_case_zero_key() public {
        uint256 key = 0;
        ValueLib.Value memory value = generateValue(100);

        vm.expectRevert(RedBlackTreeLib.ValueIsEmpty.selector);
        redBlockTreeKV.setValue(key, value);
    }

    function test_edge_case_max_key() public {
        uint256 key = type(uint256).max;
        ValueLib.Value memory value = generateValue(100);

        redBlockTreeKV.setValue(key, value);
        ValueLib.Value memory actualValue = redBlockTreeKV.getValue(key);

        assertEq(actualValue.slot2, 100);
    }

    function test_large_dataset() public {
        uint256 count = 100;

        for (uint256 i = 1; i <= count; i++) {
            redBlockTreeKV.setValue(i, generateValue(i * 10));
        }

        for (uint256 i = 1; i <= count; i++) {
            ValueLib.Value memory value = redBlockTreeKV.getValue(i);
            assertEq(value.slot2, i * 10);
        }

        uint256[] memory values = redBlockTreeKV.values();
        assertEq(values.length, count);
    }

    function test_mixed_operations() public {
        redBlockTreeKV.setValue(1, generateValue(100));
        redBlockTreeKV.setValue(2, generateValue(200));
        redBlockTreeKV.setValue(3, generateValue(300));

        redBlockTreeKV.deleteValue(2);

        redBlockTreeKV.setValue(4, generateValue(400));
        redBlockTreeKV.setValue(5, generateValue(500));

        redBlockTreeKV.deleteValue(1);
        redBlockTreeKV.deleteValue(3);

        ValueLib.Value memory value4 = redBlockTreeKV.getValue(4);
        ValueLib.Value memory value5 = redBlockTreeKV.getValue(5);

        assertEq(value4.slot2, 400);
        assertEq(value5.slot2, 500);

        uint256[] memory values = redBlockTreeKV.values();
        assertEq(values.length, 2);
    }

    function test_fuzz_setValue_getValue(uint256 key, uint256 value) public {
        vm.assume(key != 0);
        vm.assume(value != 0);

        ValueLib.Value memory testValue = generateValue(value);
        redBlockTreeKV.setValue(key, testValue);

        ValueLib.Value memory retrievedValue = redBlockTreeKV.getValue(key);

        assertEq(retrievedValue.slot1, testValue.slot1);
        assertEq(retrievedValue.slot2, testValue.slot2);
        assertEq(retrievedValue.slot3, testValue.slot3);
        assertEq(retrievedValue.slot4, testValue.slot4);
        assertEq(retrievedValue.slot5, testValue.slot5);
        assertEq(retrievedValue.slot6, testValue.slot6);
    }

    function test_fuzz_multiple_operations(uint256[10] memory keys, uint256[10] memory values) public {
        for (uint256 i = 0; i < keys.length; i++) {
            vm.assume(keys[i] != 0);
            vm.assume(values[i] != 0);
            for (uint256 j = i + 1; j < keys.length; j++) {
                vm.assume(keys[i] != keys[j]);
            }
        }

        for (uint256 i = 0; i < keys.length; i++) {
            redBlockTreeKV.setValue(keys[i], generateValue(values[i]));
        }

        for (uint256 i = 0; i < keys.length; i++) {
            ValueLib.Value memory retrievedValue = redBlockTreeKV.getValue(keys[i]);
            assertEq(retrievedValue.slot2, values[i]);
        }
    }
}
