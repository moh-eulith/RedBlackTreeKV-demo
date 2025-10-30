// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {RedBlackTreeKV} from "../src/RedBlackTreeKV1.sol";

contract MappingGasTest is Test {
    uint256 private constant _INSERT_COUNT = 1000;
    uint256 private constant KEY_ONE = 7777;
    RedBlackTreeKV public redBlackTreeKV;
    mapping(uint256 => uint256) public mappingKV;

    function setUp() public {
        redBlackTreeKV = new RedBlackTreeKV();
    }

    function beforeTestSetup(
        bytes4 testSelector
    ) public pure returns (bytes[] memory beforeTestCalldata) {
        if (testSelector == this.test_rbt_cold_insert_one.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.insertOneInTree.selector);
        }
        if (testSelector == this.test_rbt_cold_insert_2048.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.insert2048InTree.selector);
        }
        if (testSelector == this.test_rbt_hot_insert_empty.selector) {
            beforeTestCalldata = new bytes[](2);
            beforeTestCalldata[0] = abi.encodePacked(this.insertOneInTree.selector);
            beforeTestCalldata[1] = abi.encodePacked(this.deleteOneInTree.selector);
        }
        if (testSelector == this.test_rbt_hot_insert_one.selector) {
            beforeTestCalldata = new bytes[](2);
            beforeTestCalldata[0] = abi.encodeWithSignature("insertOneInTreeKey(uint256)", 999);
            beforeTestCalldata[1] = abi.encodeWithSignature("deleteOneInTreeKey(uint256)", 999);
        }
        if (testSelector == this.test_rbt_hot_insert_2048.selector) {
            beforeTestCalldata = new bytes[](3);
            beforeTestCalldata[0] = abi.encodePacked(this.insert2048InTree.selector);
            beforeTestCalldata[1] = abi.encodeWithSignature("insertOneInTreeKey(uint256)", 999);
            beforeTestCalldata[2] = abi.encodeWithSignature("deleteOneInTreeKey(uint256)", 999);
        }
        if (testSelector == this.test_rbt_delete_one.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.insertOneInTree.selector);
        }
        if (testSelector == this.test_rbt_delete_2048.selector) {
            beforeTestCalldata = new bytes[](2);
            beforeTestCalldata[0] = abi.encodePacked(this.insertOneInTree.selector);
            beforeTestCalldata[1] = abi.encodePacked(this.insert2048InTree.selector);
        }
        if (testSelector == this.test_rbt_read_one.selector) {
            beforeTestCalldata = new bytes[](1);
            beforeTestCalldata[0] = abi.encodePacked(this.insertOneInTree.selector);
        }
        if (testSelector == this.test_rbt_read_2048.selector) {
            beforeTestCalldata = new bytes[](2);
            beforeTestCalldata[0] = abi.encodePacked(this.insertOneInTree.selector);
            beforeTestCalldata[1] = abi.encodePacked(this.insert2048InTree.selector);
        }
        if (testSelector == this.test_rbt_transfer_one.selector) {
            beforeTestCalldata = new bytes[](2);
            beforeTestCalldata[0] = abi.encodeWithSignature("insertOneInTreeKey(uint256)", 999);
            beforeTestCalldata[1] = abi.encodeWithSignature("insertOneInTreeKey(uint256)", 1000);
        }
        if (testSelector == this.test_rbt_transfer_2048.selector) {
            beforeTestCalldata = new bytes[](3);
            beforeTestCalldata[0] = abi.encodePacked(this.insert2048InTree.selector);
            beforeTestCalldata[1] = abi.encodeWithSignature("insertOneInTreeKey(uint256)", 999);
            beforeTestCalldata[2] = abi.encodeWithSignature("insertOneInTreeKey(uint256)", 1000);
        }
        if (testSelector == this.test_mapping_transfer.selector) {
            beforeTestCalldata = new bytes[](2);
            beforeTestCalldata[0] = abi.encodeWithSignature("insertOneInMappingKey(uint256)", 999);
            beforeTestCalldata[1] = abi.encodeWithSignature("insertOneInMappingKey(uint256)", 1000);
        }
    }

    function insert2048InTree() public {
        for (uint256 i = 0; i < 2048; i += 1) {
            uint256 orderId1 = uint256(keccak256(abi.encodePacked("pre", i)));
            redBlackTreeKV.setValue(orderId1, generateValue(i+1));
        }
    }

    function insertOneInTree() public {
        insertOneInTreeKey(KEY_ONE);
    }

    function deleteOneInTree() public {
        deleteOneInTreeKey(KEY_ONE);
    }

    function insertOneInTreeKey(uint256 key) public {
        uint256 orderId1 = uint256(keccak256(abi.encodePacked("valueOne", key)));

        uint256 gasBefore = gasleft();
        redBlackTreeKV.setValue(orderId1, 100);
        uint256 gasAfter = gasleft();
        console.log("gas used one insert", gasBefore - gasAfter);
    }

    function insertOneInMappingKey(uint256 key) public {
        uint256 orderId1 = uint256(keccak256(abi.encodePacked("valueOne", key)));

        uint256 gasBefore = gasleft();
        mappingKV[orderId1] = 100;
        uint256 gasAfter = gasleft();
        console.log("gas used one insert", gasBefore - gasAfter);
    }

    function deleteOneInTreeKey(uint256 key) public {
        uint256 orderId1 = uint256(keccak256(abi.encodePacked("valueOne", key)));
        uint256 gasBefore = gasleft();
        redBlackTreeKV.deleteValue(orderId1);
        uint256 gasAfter = gasleft();
        console.log("gas used one delete", gasBefore - gasAfter);
    }
    
    function readOneInTreeKey(uint256 key) public {
        uint256 orderId1 = uint256(keccak256(abi.encodePacked("valueOne", key)));
        uint256 gasBefore = gasleft();
        redBlackTreeKV.getValue(orderId1);
        uint256 gasAfter = gasleft();
        console.log("gas used one read", gasBefore - gasAfter);
    }
    
    function transferInTreeKey(uint256 key) public {
        uint256 orderId1 = uint256(keccak256(abi.encodePacked("valueOne", key)));
        uint256 orderId2 = uint256(keccak256(abi.encodePacked("valueOne", key+1)));

        uint256 gasBefore = gasleft();
        uint256 v1 = redBlackTreeKV.getValue(orderId1);
        uint256 v2 = redBlackTreeKV.getValue(orderId2);
        redBlackTreeKV.deleteValue(orderId1);
        redBlackTreeKV.setValue(orderId1, v1 - 1);
        redBlackTreeKV.deleteValue(orderId2);
        redBlackTreeKV.setValue(orderId2, v2 + 1);
        uint256 gasAfter = gasleft();
        console.log("gas used one transfer", gasBefore - gasAfter);
    }

    function transferInMappingKey(uint256 key) public {
        uint256 orderId1 = uint256(keccak256(abi.encodePacked("valueOne", key)));
        uint256 orderId2 = uint256(keccak256(abi.encodePacked("valueOne", key+1)));

        uint256 gasBefore = gasleft();
        mappingKV[orderId1] -= 1;
        mappingKV[orderId2] += 1;
        uint256 gasAfter = gasleft();
        console.log("gas used one transfer", gasBefore - gasAfter);
    }

    function test_rbt_cold_insert_empty() public {
        insertOneInTreeKey(12);
    }

    function test_rbt_cold_insert_one() public {
        insertOneInTreeKey(13);
    }

    function test_rbt_cold_insert_2048() public {
        insertOneInTreeKey(14);
    }

    function test_rbt_hot_insert_empty() public {
        insertOneInTreeKey(12);
    }

    function test_rbt_hot_insert_one() public {
        insertOneInTreeKey(13);
    }

    function test_rbt_hot_insert_2048() public {
        insertOneInTreeKey(14);
    }

    function test_rbt_delete_one() public {
        deleteOneInTreeKey(KEY_ONE);
    }

    function test_rbt_delete_2048() public {
        deleteOneInTreeKey(KEY_ONE);
    }

    function test_rbt_read_one() public {
        readOneInTreeKey(KEY_ONE);
    }

    function test_rbt_read_2048() public {
        readOneInTreeKey(KEY_ONE);
    }

    function test_rbt_transfer_one() public {
        transferInTreeKey(999);
    }

    function test_rbt_transfer_2048() public {
        transferInTreeKey(999);
    }

    function test_mapping_transfer() public {
        transferInMappingKey(999);
    }

    function generateValue(uint256 value) internal pure returns (uint256) {
        return value;
    }

    function test_rbt_add_value() public {
        uint256 orderId = uint256(keccak256("value1"));
        uint256 gasBefore = gasleft();
        redBlackTreeKV.setValue(orderId, generateValue(1));
        uint256 gasAfter = gasleft();
        console.log("gas used", gasBefore - gasAfter);
        redBlackTreeKV.deleteValue(orderId);
        gasBefore = gasleft();
        redBlackTreeKV.setValue(orderId, generateValue(2));
        gasAfter = gasleft();
        console.log("gas used", gasBefore - gasAfter);
    }

    function test_rbt_add_value_2() public {
        // stage 1:
        console.log("add value gas usage:");

        uint256 gasBefore = gasleft();
        redBlackTreeKV.setValue(uint256(keccak256("value1")), generateValue(1));
        uint256 gasAfter = gasleft();
        console.log("insert 1 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlackTreeKV.setValue(uint256(keccak256("value2")), generateValue(2));
        gasAfter = gasleft();
        console.log("insert 2 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlackTreeKV.setValue(uint256(keccak256("value3")), generateValue(3));
        gasAfter = gasleft();
        console.log("insert 3 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlackTreeKV.setValue(uint256(keccak256("value4")), generateValue(4));
        gasAfter = gasleft();
        console.log("insert 4 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlackTreeKV.setValue(uint256(keccak256("value5")), generateValue(5));
        gasAfter = gasleft();
        console.log("insert 5 gas used", gasBefore - gasAfter);

        // stage 2:
        console.log("delete value gas usage:");

        gasBefore = gasleft();
        redBlackTreeKV.deleteValue(uint256(keccak256("value2")));
        gasAfter = gasleft();
        console.log("delete 2 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlackTreeKV.deleteValue(uint256(keccak256("value3")));
        gasAfter = gasleft();
        console.log("delete 3 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlackTreeKV.deleteValue(uint256(keccak256("value4")));
        gasAfter = gasleft();
        console.log("delete 4 gas used", gasBefore - gasAfter);

        // stage 3:
        console.log("add value gas usage:");

        gasBefore = gasleft();
        redBlackTreeKV.setValue(uint256(keccak256("value6")), generateValue(6));
        gasAfter = gasleft();
        console.log("insert 6 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlackTreeKV.setValue(uint256(keccak256("value7")), generateValue(7));
        gasAfter = gasleft();
        console.log("insert 7 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlackTreeKV.setValue(uint256(keccak256("value8")), generateValue(8));
        gasAfter = gasleft();
        console.log("insert 8 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlackTreeKV.setValue(uint256(keccak256("value9")), generateValue(9));
        gasAfter = gasleft();
        console.log("insert 9 gas used", gasBefore - gasAfter);

        gasBefore = gasleft();
        redBlackTreeKV.setValue(uint256(keccak256("value10")), generateValue(10));
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
        redBlackTreeKV.setValue(uint256(keccak256(abi.encodePacked("valueMAX"))), generateValue(UINT256_MAX));
        redBlackTreeKV.setValue(uint256(keccak256(abi.encodePacked("valueMAX-1"))), generateValue(UINT256_MAX - 1));
        redBlackTreeKV.deleteValue(uint256(keccak256(abi.encodePacked("valueMAX"))));
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
            redBlackTreeKV.setValue(orderId1, generateValue(i));
            gasAfter = gasleft();
            totalHotInsertGas += gasBefore - gasAfter;
            gasBefore = gasleft();
            redBlackTreeKV.setValue(orderId2, generateValue(i + 1));
            gasAfter = gasleft();
            totalColdInsertGas += gasBefore - gasAfter;
            gasBefore = gasleft();
            redBlackTreeKV.deleteValue(orderId1);
            gasAfter = gasleft();
            totalDeleteGas += gasBefore - gasAfter;
        }
        console.log("_INSERT_COUNT", _INSERT_COUNT);
        console.log("avgColdInsertGas", totalColdInsertGas / _INSERT_COUNT);
        console.log("avgHotInsertGas", totalHotInsertGas / _INSERT_COUNT);
        console.log("avgDeleteGas", totalDeleteGas / _INSERT_COUNT);
        for (uint256 i = 1; i <= _INSERT_COUNT * 2; i += 2) {
            uint256 orderId2 = uint256(keccak256(abi.encodePacked("value", i + 1)));
            uint256 value = redBlackTreeKV.getValue(orderId2);
            assertEq(value, uint256(i + 1));
        }
    }

    // Insert is largely gas-consuming
    /// _INSERT_COUNT 1000
    /// avgInsertGas 135350 <- High!
    /// avgDeleteGas 1529
    function test_mapping_fully_insert() public {
        // init, insert 2 values and delete 1
        mappingKV[uint256(keccak256(abi.encodePacked("valueMAX")))] = generateValue(UINT256_MAX);
        mappingKV[uint256(keccak256(abi.encodePacked("valueMAX-1")))] = generateValue(UINT256_MAX - 1);
        delete mappingKV[uint256(keccak256(abi.encodePacked("valueMAX")))];
        uint256 gasBefore;
        uint256 gasAfter;
        uint256 totalInsertGas = 0;
        uint256 totalDeleteGas = 0;
        // each loop: insert 2 values and delete 1, first insert is hot, second is cold
        for (uint256 i = 1; i <= _INSERT_COUNT * 2; i += 2) {
            uint256 orderId1 = uint256(keccak256(abi.encodePacked("value", i)));
            uint256 orderId2 = uint256(keccak256(abi.encodePacked("value", i + 1)));
            gasBefore = gasleft();
            mappingKV[orderId1] = generateValue(i);
            gasAfter = gasleft();
            totalInsertGas += gasBefore - gasAfter;
            gasBefore = gasleft();
            mappingKV[orderId2] = generateValue(i + 1);
            gasAfter = gasleft();
            totalInsertGas += gasBefore - gasAfter;
            gasBefore = gasleft();
            delete mappingKV[orderId1];
            gasAfter = gasleft();
            totalDeleteGas += gasBefore - gasAfter;
        }
        console.log("_INSERT_COUNT", _INSERT_COUNT);
        console.log("avgInsertGas", totalInsertGas / _INSERT_COUNT / 2);
        console.log("avgDeleteGas", totalDeleteGas / _INSERT_COUNT);
        for (uint256 i = 1; i <= _INSERT_COUNT * 2; i += 2) {
            uint256 orderId2 = uint256(keccak256(abi.encodePacked("value", i + 1)));
            uint256 value = mappingKV[orderId2];
            assertEq(value, uint256(i + 1));
        }
    }
}
