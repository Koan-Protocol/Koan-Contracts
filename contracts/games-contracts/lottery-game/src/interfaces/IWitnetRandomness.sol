// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IWitnetRandomness
 * @notice Minimal interface for the on-chain WitnetRandomness contract.
 * @dev Only the subset of functions used by RandomNumberGenerator is included.
 *      The full interface lives in the `witnet-solidity-bridge` npm package.
 *
 * Deployed addresses (same on mainnet & testnets):
 *   Celo / Alfajores:  0x77703aE126B971c9946d562F41Dd47071dA00777
 */
interface IWitnetRandomness {
    /**
     * @notice Request the oracle to generate a new random seed.
     * @dev    Must be called with `{value: fee}` where `fee >= estimateRandomizeFee(...)`.
     * @return usedFunds  Amount of native token actually consumed.
     */
    function randomize() external payable returns (uint256 usedFunds);

    /**
     * @notice Estimate the fee (in native token) required for the next `randomize()` call.
     * @param  _gasPrice  Current `tx.gasprice` or caller-chosen gas price.
     */
    function estimateRandomizeFee(uint256 _gasPrice) external view returns (uint256);

    /**
     * @notice Derive a random uint32 in [0, _range) using the seed that was generated
     *         at or after block `_blockNumber`.
     * @param  _range        Upper-bound (exclusive). Pass `type(uint32).max` for full range.
     * @param  _nonce        Application-level nonce for domain separation.
     * @param  _blockNumber  Block at which `randomize()` was called.
     * @return A pseudo-random uint32 in [0, _range).
     */
    function random(
        uint32 _range,
        uint256 _nonce,
        uint256 _blockNumber
    ) external view returns (uint32);

    /**
     * @notice Return the raw 32-byte random seed generated at or after `_blockNumber`.
     */
    function getRandomnessAfter(uint256 _blockNumber) external view returns (bytes32);

    /**
     * @notice Check whether the randomness for the given block has been reported.
     */
    function isRandomized(uint256 _blockNumber) external view returns (bool);
}
