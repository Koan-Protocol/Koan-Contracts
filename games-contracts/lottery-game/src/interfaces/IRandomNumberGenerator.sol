// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getLotteryWinningNumber() external;

    /**
     * View latest lotteryId numbers
     */
    function viewLatestLotteryId() external view returns (uint256);

    function setLatestLotteryId(uint256 _latestLotteryId) external;

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint32);
}
