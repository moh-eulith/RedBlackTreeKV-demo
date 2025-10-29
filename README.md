# Issues with the previous methodology:

- It uses 6 slots for the value. Most contracts/mappings need just one. Examples: ERC20 balance, approval, etc.
  - this minimizes the fact that a tree needs to store keys, values and tree-node-metadata, whereas the solidity mapping just stores values.
- It's using forge's test framework, which does everything in a single transaction.
  - This is very much unlike how transactions happen on a real blockchain: approvals, transfers, orders, etc, happen one at a time in their own transaction
  - The effect here is to minimize the extra cost incurred in traversing a tree (from 2100 gas to 100 gas per read)
- There are two types of "hot" inserts: 
  - inserts done in the same transaction after removing a value
  - inserts done in different transactions, where the new insert follows an old delete
- It's basically using an emtpy tree. Tree size matters because it's an `O(log n)` structure, not a O(1) like solidity mappings
  - the size of the tree represents natural growth in data structures. Some examples:
    - ERC20's ledger grows with the number of people who have that token
    - Uniswap's books grow with the number of LPs.
    - Aave's ledger grows with the number of people who are lending or borrowing
- There are no tests for reads. Reads get progressively more expensive with tree size, but are constant for solidity mapping

To address these issues:
- We'll use a single slot map. Coded in `RedBlackTreeKV1.sol`
- We'll code our forge tests with `beforeTestSetup` and do a single insert in the measured transaction
- We'll consider hot inserts in different transactions. It's unclear under what conditions a contract would benefit from removing key A, adding key B in the same exact transaction.
- We'll do tests for various tree sizes
- We'll add tests for reads as well as writes

The code for the above can be seen in `RedBlackTreeKV1Gas.t.sol`

# Results
Under normal EVM gas costs (as measured here and in the original code):
- Cold inserts are 4x as expensive in an empty tree. This grows to 6x if the tree has 2000 elements or more.
- Hot inserts start at around 2.5x as expensive, then grow to 4x if the tree has 2000 elements or more.
- Deletes are very expensive (10x or more) in a tree and get worse with size.
- Reads are generally very expensive. They start at 6x the cost, then get progressively worse with size. By the time there are 2000 entries in the tree, reads are 25x as expensive.

This is summarized in the table below (percents in parentheses are with respect to solidity mapping)

| Data Structure / Entries | Cold Insert        | Hot Insert          | Delete             | Read               |
|--------------------------|--------------------|---------------------|--------------------|--------------------|
| Solidity Mapping Cost    | 22000 (100%)       | 22000 (100%)        | 1600 (100%)        | 2500 (100%)        |
| Tree Cost (empty)        | 95646 (434%)       | 58646 (266%)        | --                 | --                 |
| Tree Cost (one entry)    | 103780 (472%)      | 58646 (266%)        | 18079 (1130%)      | 14275 (571%)       |
| Tree Cost (2048 entries) | 138075 (628%)      | 83975 (382%)        | 104729 (6545%)     | 61982 (2479%)      |


# Discussion
So are trees just evil data structures? No, absolutely not. If you need a tree, especially the sorted variety, a red-black tree is great.
On the other hand, if all you need is a map, there is no escaping the fact that:

- Trees are `O(log n)`. The more users you have, **the more expensive all operations become for all users**.
- Computing gas cost becomes more difficult: going from constant values to values that depend on data completely external to the transaction is just harder.

The other part of the discussion here is tree size. In many apps, that corresponds to the number of users.
If you have an app that will never have 2000 or more users and you do a lot of inserts and deletes, tree may be a win.
(That also applies to any data structure that stays small).

## How much of a win is this if SSTORE costs 2M gas?
Overall, tree size becomes less of a factor because reads are kept at 2100 gas. The following is a theoretical estimate of
what would happen, actual results may be different:
- Cold inserts are 4x as expensive and grow (much slower) with tree size.
  - There is no way around this. A tree has to store more information (the key plus the metadata).
  - There is only a special exception for values that are smaller than 2^31, a far cry from 2^256 that's native to the EVM.
- Hot inserts are hard to reason about. The code must be executed against a live testnet.
- Deletes will still be very expensive in a tree 
- Reads remain expensive: they get progressively worse with size. By the time there are 2000 entries, reads are 25x as expensive.

## Why are reads important?
Reads happen all the time when a smart contract needs to do its work. Imagine a simple swap transaction. We need to minimally read:

- The current book (AMM or orderbook)'s tip, potentially more for larger orders.
- The balance of the user doing the swap on both tokens.
- The balance of the contract doing the swap on both tokens.

Some of this data will live in the same tree, some not.
Generally speaking, transactions can spend as much as 10% of their gas usage on reads, because it's the second most expensive opcode. 
It costs 2100 gas, compared to just 3, for example, for adding two numbers. If that 10% balloons by 25x, the full transaction will be 3x as expensive.

## Why are cold inserts important?
Cold inserts represent growth. Sometimes that's very easy to reason about, e.g. number of users. 
Questions like this come to mind:

- Will your application have 2000 users or more?
- Do you want to lose a user for every user you get? (If so, hot inserts will work for your case)

There are many more use cases where data grows with time. Chainlink oracles, for example, provide historical data.
New prices will never hit a hot insert.

## What about datastructures that are not maps?
Trees are not helpful, clearly.

## Why is changing existing contracts not a great idea?
- Solidity mappings have different update semantics: it's perfectly valid to overwrite an existing value.
  - With this RedBlackTreeLib, to overwrite a value, one must: check if it exists, if so, delete it, then insert.
  - All existing code that overwrite must be changed to do an upsert.
- Contracts are often written carefully, audited extensively and at great cost. Making random changes, that can for example, cause
an exception when an upsert was missed is not a sensible solution.
- Existing projects rely on having the exact same binary deployed so it's verifiable. This will all break.

------------------- Original Readme below

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
