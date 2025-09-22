// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {RedBlackTreeLib} from "./lib/RedBlackTreeLib.sol";
import {ValueLib} from "./lib/Value.sol";

// A simple RBT kv example. It is gas-efficient if frequently add & remove.
contract RedBlackTreeKV {
    uint256 private constant _DATA_SLOT_SEED = 0xdeadbeef; // Arbitrary unique seed
    uint256 private constant _SLOTS_PER_POSITION = ValueLib.SLOTS_PER_POSITION; // Dense slots per value

    RedBlackTreeLib.Tree public tree;

    using RedBlackTreeLib for RedBlackTreeLib.Tree;

    function setValue(uint256 key, ValueLib.Value memory value) public {
        tree.insert(key);
        bytes32 ptr = tree.find(key);
        (, uint256 index) = _unpack(ptr); // Extract dense node index
        uint256 dataBase = _dataBase();
        uint256 valueSlot = dataBase + index * _SLOTS_PER_POSITION;
        /// @solidity memory-safe-assembly
        assembly {
            sstore(valueSlot, mload(value))
            sstore(add(valueSlot, 1), mload(add(value, 0x20)))
            sstore(add(valueSlot, 2), mload(add(value, 0x40)))
            sstore(add(valueSlot, 3), mload(add(value, 0x60)))
            sstore(add(valueSlot, 4), mload(add(value, 0x80)))
            sstore(add(valueSlot, 5), mload(add(value, 0xa0)))
        }
    }

    function getValue(uint256 key) public view returns (ValueLib.Value memory) {
        bytes32 ptr = tree.find(key);
        (, uint256 index) = _unpack(ptr); // Extract dense node index
        uint256 dataBase = _dataBase();
        uint256 valueSlot = dataBase + index * _SLOTS_PER_POSITION;
        ValueLib.Value memory value;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(value, sload(valueSlot))
            mstore(add(value, 0x20), sload(add(valueSlot, 1)))
            mstore(add(value, 0x40), sload(add(valueSlot, 2)))
            mstore(add(value, 0x60), sload(add(valueSlot, 3)))
            mstore(add(value, 0x80), sload(add(valueSlot, 4)))
            mstore(add(value, 0xa0), sload(add(valueSlot, 5)))
        }
        return value;
    }

    function deleteValue(uint256 key) public {
        bytes32 ptr = tree.find(key);
        (, uint256 deletedIndex) = _unpack(ptr); // Extract dense node index
        uint256 dataBase = _dataBase();
        uint256 deletedSlot = dataBase + deletedIndex * _SLOTS_PER_POSITION;

        uint256 treeSize = tree.size();
        uint256 lastIndex = treeSize;
        bool needsCopy = (deletedIndex != lastIndex);
        uint256 lastSlot = dataBase + lastIndex * _SLOTS_PER_POSITION;

        tree.remove(key);

        if (needsCopy) {
            /// @solidity memory-safe-assembly
            assembly {
                /// @dev 6 = _SLOTS_PER_POSITION
                for { let i := 0 } lt(i, 6) { i := add(i, 1) } { sstore(add(deletedSlot, i), sload(add(lastSlot, i))) }
            }
        }
    }

    // Helper: Compute data base slot (keccak-based, like tree nodes but unique seed)
    function _dataBase() internal pure returns (uint256 slotBase) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, tree.slot)
            mstore(0x00, _DATA_SLOT_SEED)
            slotBase := keccak256(0x00, 0x40)
        }
    }

    // Helper: Unpack pointer (copied from lib private _unpack for convenience)
    function _unpack(bytes32 ptr) internal pure returns (uint256 nodes, uint256 key) {
        /// @solidity memory-safe-assembly
        assembly {
            nodes := shl(32, shr(32, ptr)) // _NODES_SLOT_SHIFT == 32
            key := and(0x7fffffff, ptr) // _BITMASK_KEY == (1 << 31) - 1
        }
    }

    function values() public view returns (uint256[] memory) {
        return tree.values();
    }
}
