# RedBlackTree KV Demo

A demonstration of a gas-efficient key-value store implementation using Red-Black Tree data structure in Solidity. This project showcases how Red-Black Trees can be more gas-efficient than traditional mapping-based storage when frequently adding and removing values.

## Overview

This project implements a Red-Black Tree based key-value store (`RedBlackTreeKV`) that stores complex value structures efficiently. The implementation is particularly beneficial for use cases involving frequent insertions and deletions, as it reuses storage slots and minimizes gas consumption.

The Red-Black Tree implementation is based on [Solady's RedBlackTreeLib](https://github.com/vectorized/solady/blob/main/src/utils/RedBlackTreeLib.sol). In this example, we modified the `remove` function to prevent deleting storage when removing nodes, enabling storage slot reuse for subsequent insertions.

### Key Features

- **Gas-Efficient Storage**: Reuses storage slots when items are deleted, leading to significant gas savings on subsequent insertions
- **Complex Value Support**: Stores `ValueLib.Value` structs containing any size of data. In this example, it shows 6 slots.
- **Red-Black Tree Properties**: Maintains balanced tree structure ensuring O(log n) operations
- **Zero Value Protection**: Prevents insertion of zero keys to maintain tree integrity

### Gas Performance

Based on benchmark tests with 1,000 operations:

**RedBlackTreeKV:**

- Cold Insert: ~188,984 gas
- Hot Insert (reusing deleted slot): ~13,250 gas ⚡
- Delete: ~12,876 gas

**Traditional Mapping:**

- Insert: ~135,350 gas
- Delete: ~1,529 gas

The Red-Black Tree implementation shows **90% gas reduction** for hot insertions compared to cold insertions, making it highly efficient for applications with frequent add/remove patterns.

> **Note for MegaETH**: On MegaETH where SSTORE operations cost significantly more than standard EVM, the gas efficiency advantage of RedBlackTreeKV becomes even more pronounced due to its storage slot reuse optimization.

## Project Structure

```
src/
├── RedBlackTreeKV.sol      # Main KV store implementation
├── MappingKV.sol          # Traditional mapping implementation for comparison
└── lib/
    ├── RedBlackTreeLib.sol # Red-Black Tree data structure library
    └── Value.sol          # Value struct definition

test/
├── RedBlackTreeKV.t.sol     # Comprehensive unit tests
└── RedBlackTreeKVGas.t.sol  # Gas benchmark tests
```

## Value Structure

The KV store works with `ValueLib.Value` structs:

```solidity
struct Value {
    bytes32 slot1;  // 32 bytes
    uint256 slot2;  // 32 bytes
    int256 slot3;   // 32 bytes
    bytes32 slot4;  // 32 bytes
    uint256 slot5;  // 32 bytes
    address slot6;  // 20 bytes
}
// Total: 192 bytes (6 storage slots)
```

## Usage

### Basic Operations

```solidity
RedBlackTreeKV kv = new RedBlackTreeKV();

// Create a value
ValueLib.Value memory value = ValueLib.Value({
    slot1: bytes32(uint256(100)),
    slot2: 100,
    slot3: int256(100),
    slot4: bytes32(uint256(100)),
    slot5: 100,
    slot6: address(uint160(100))
});

// Set value
kv.setValue(1, value);

// Get value
ValueLib.Value memory retrieved = kv.getValue(1);

// Delete value
kv.deleteValue(1);

// Get all keys (sorted)
uint256[] memory keys = kv.values();
```

### Constraints

- **No Zero Keys**: Keys cannot be 0 (will revert with `ValueIsEmpty()`)
- **No Duplicate Keys**: Attempting to set an existing key will revert with `ValueAlreadyExists()`
- **Key Must Exist for Deletion**: Deleting non-existent keys will revert with `ValueDoesNotExist()`

## Development

### Build

```shell
forge build
```

### Test

```shell
# Run all tests
forge test

# Run unit tests only
forge test --match-contract RedBlackTreeKVTest

# Run gas benchmarks
forge test --match-contract MappingGasTest -vv
```

### Test Coverage

The test suite includes:

- ✅ Basic CRUD operations
- ✅ Edge cases (zero keys, max values)
- ✅ Multiple value operations
- ✅ Delete and reuse scenarios
- ✅ Large dataset handling (100+ items)
- ✅ Fuzz testing with random inputs
- ✅ Gas consumption benchmarks

## Use Cases

This implementation is ideal for:

- **Order Books**: Frequent order insertions and cancellations
- **Gaming**: Player inventory systems with item trading
- **DeFi Protocols**: Position management with frequent updates
- **NFT Marketplaces**: Listing and delisting operations

## License

MIT
