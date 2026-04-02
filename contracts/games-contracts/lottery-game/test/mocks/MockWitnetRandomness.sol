// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IWitnetRandomness} from "../../src/interfaces/IWitnetRandomness.sol";

/**
 * @title MockWitnetRandomness
 * @notice A test-only mock that simulates the Witnet two-step randomness flow
 *         for Foundry tests.
 *
 * Usage in tests:
 *   1. The lottery calls `rng.getLotteryWinningNumber()` which internally calls
 *      `witnet.randomize()`.  The mock records `latestRandomizingBlock`.
 *   2. The test calls `mock.setRandomnessResult(blockNumber, rawUint32)` to
 *      simulate the Witnet oracle reporting the seed.
 *   3. The operator (or anyone) calls `rng.fetchAndStoreRandom()` which reads
 *      the seed via `witnet.random(...)`.
 */
contract MockWitnetRandomness is IWitnetRandomness {
    // blockNumber => raw uint32 result set by the test
    mapping(uint256 => uint32) private _randomResults;
    mapping(uint256 => bool) private _isRandomized;

    uint256 public lastRandomizedBlock;
    uint256 public mockFee;

    constructor() {
        mockFee = 0; // free in tests
    }

    // ─── Test helpers ───────────────────────────────────────────────

    /**
     * @notice Simulate the oracle reporting a random seed for a given block.
     * @param _blockNumber  The block at which randomize() was called.
     * @param _rawRandom    The raw uint32 that `random()` will return.
     */
    function setRandomnessResult(uint256 _blockNumber, uint32 _rawRandom) external {
        _randomResults[_blockNumber] = _rawRandom;
        _isRandomized[_blockNumber] = true;
    }

    /**
     * @notice Convenience: set the fee that `estimateRandomizeFee` returns.
     */
    function setMockFee(uint256 _fee) external {
        mockFee = _fee;
    }

    // ─── IWitnetRandomness implementation ───────────────────────────

    function randomize() external payable override returns (uint256 usedFunds) {
        lastRandomizedBlock = block.number;
        usedFunds = mockFee;
    }

    function estimateRandomizeFee(uint256 /*_gasPrice*/) external view override returns (uint256) {
        return mockFee;
    }

    function random(
        uint32 /*_range*/,
        uint256 /*_nonce*/,
        uint256 _blockNumber
    ) external view override returns (uint32) {
        require(_isRandomized[_blockNumber], "MockWitnet: not yet randomized");
        return _randomResults[_blockNumber];
    }

    function getRandomnessAfter(uint256 _blockNumber) external view override returns (bytes32) {
        require(_isRandomized[_blockNumber], "MockWitnet: not yet randomized");
        return bytes32(uint256(_randomResults[_blockNumber]));
    }

    function isRandomized(uint256 _blockNumber) external view override returns (bool) {
        return _isRandomized[_blockNumber];
    }
}
