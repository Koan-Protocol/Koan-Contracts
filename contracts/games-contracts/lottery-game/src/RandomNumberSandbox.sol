// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IWitnetRandomness} from "./interfaces/IWitnetRandomness.sol";

/**
 * @title KoanProtocolWitnetRandomnessSandbox
 * @notice A standalone contract to verify Witnet's randomness on Celo Mainnet.
 * 
 * Deployment: Use constructor with 0x77703aE126B971c9946d562F41Dd47071dA00777
 * 1. Deploy & Fund with some CELO.
 * 2. Call requestRandomNumber().
 * 3. Wait 5-10 mins.
 * 4. Call fetchRandomNumber().
 * 5. Check 'latestRandomValue'.
 */
contract KoanProtocolWitnetRandomnessSandbox {
    IWitnetRandomness public immutable WITNET;
    
    uint256 public latestRandomizingBlock;
    uint32 public latestRandomValue;
    uint256 public lastResponseTimestamp;

    event RandomnessRequested(uint256 blockNumber);
    event RandomnessReceived(uint32 value);

    constructor(address _witnetRandomness) {
        WITNET = IWitnetRandomness(_witnetRandomness);
    }

    /// @notice Allow contract to receive CELO for fees.
    receive() external payable {}

    /**
     * @notice Step 1: Request randomness.
     */
    function requestRandomNumber() external payable {
        latestRandomizingBlock = block.number;
        latestRandomValue = 0; // Reset for new test

        // Estimate & pay Witnet fee
        uint256 fee = WITNET.estimateRandomizeFee(tx.gasprice);
        WITNET.randomize{value: fee}();

        emit RandomnessRequested(latestRandomizingBlock);
    }

    /**
     * @notice Step 2: Fetch randomness after oracle has reported (5-10 mins).
     */
    function fetchRandomNumber() external {
        require(latestRandomizingBlock > 0, "Request randomness first");
        
        // Fetch raw uint32
        uint32 rawRandom = WITNET.random(
            type(uint32).max,
            0,
            latestRandomizingBlock
        );

        // Map to lottery range [1,000,000 - 1,999,999] just like the real one
        latestRandomValue = uint32(1000000 + (uint256(rawRandom) % 1000000));
        lastResponseTimestamp = block.timestamp;

        emit RandomnessReceived(latestRandomValue);
    }

    /**
     * @notice Check if the oracle has already reported the randomness.
     */
    function isRandomReady() external view returns (bool) {
        return WITNET.isRandomized(latestRandomizingBlock);
    }

    /**
     * @notice Helper to see current fee estimate.
     */
    function currentFeeEstimate() external view returns (uint256) {
        return WITNET.estimateRandomizeFee(tx.gasprice);
    }
}
