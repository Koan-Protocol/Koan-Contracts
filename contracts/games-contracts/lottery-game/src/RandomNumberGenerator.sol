// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IKoanPlayLottery} from "./interfaces/IKoanPlayLottery.sol";
import {IWitnetRandomness} from "./interfaces/IWitnetRandomness.sol";

/**
 * @title RandomNumberGenerator
 * @notice Generates verifiable random numbers for the Koan Lottery using Witnet's
 *         decentralised randomness oracle.
 *
 * @dev Witnet randomness follows a **two-step** asynchronous flow:
 *  1. `getLotteryWinningNumber()` — pays the Witnet fee and calls
 *     `witnet.randomize{value: fee}()`, recording the block number at which the
 *     request was made (`latestRandomizingBlock`).
 *  2. `fetchAndStoreRandom()` — called once the Witnet oracle has reported the
 *     random seed (typically 5-10 min later). It reads the random value via
 *     `witnet.random()` and stores a lottery-compatible `randomResult` in the
 *     range [1_000_000, 1_999_999].
 *
 * The lottery contract calls `viewRandomResult()` to read the stored number and
 * uses it to determine a winning ticket.
 */
contract RandomNumberGenerator is Ownable {
    using SafeERC20 for IERC20;

    // ──────────────────────────── State ────────────────────────────

    address public admin;
    address public koanPlayLottery;

    uint256 public latestLotteryId;
    uint32 public randomResult;

    /// @notice Witnet randomness oracle contract.
    IWitnetRandomness public immutable WITNET;

    /// @notice Block number at which `randomize()` was last called.
    uint256 public latestRandomizingBlock;

    // ──────────────────────────── Errors ───────────────────────────

    error OnlyAdmin();
    error OnlyLotteryContract();
    error OnlyLottery();
    error RandomnessNotYetReported();
    error AlreadyFetched();

    // ──────────────────────────── Modifiers ────────────────────────

    modifier isAdmin() {
        _isAdmin();
        _;
    }

    function _isAdmin() internal view {
        if (msg.sender != admin) revert OnlyAdmin();
    }

    modifier isLotteryContract() {
        _isLotteryContract();
        _;
    }

    function _isLotteryContract() internal view {
        if (
            msg.sender != koanPlayLottery &&
            msg.sender != IKoanPlayLottery(koanPlayLottery).operatorAddress()
        ) revert OnlyLotteryContract();
    }

    // ──────────────────────────── Constructor ──────────────────────

    /**
     * @param _witnetRandomness Address of the deployed WitnetRandomness contract
     *        on the target chain (e.g. 0x77703aE126B971c9946d562F41Dd47071dA00777 on Celo).
     */
    constructor(address _witnetRandomness) Ownable(msg.sender) {
        require(_witnetRandomness != address(0), "Witnet address cannot be 0");
        WITNET = IWitnetRandomness(_witnetRandomness);
        admin = msg.sender;
    }

    /// @notice Allow native token deposits so the contract can pay Witnet fees.
    receive() external payable {}

    // ──────────────────────── Lottery Flow ─────────────────────────

    /**
     * @notice Step 1 — Request randomness from Witnet.
     * @dev Called by the lottery contract when a round is closed.
     *      The contract must hold enough native token (CELO) to cover the
     *      Witnet randomize fee. Any excess is kept for the next request.
     */
    function getLotteryWinningNumber() external {
        require(msg.sender == koanPlayLottery, "Only koanPlayLottery");

        // Reset previous result so `viewRandomResult` is invalid until
        // `fetchAndStoreRandom` is called.
        randomResult = 0;

        // Record the block number *before* calling randomize, so the seed is
        // guaranteed to be generated after this point.
        latestRandomizingBlock = block.number;

        // Pay the Witnet fee from the contract's native balance.
        uint256 fee = WITNET.estimateRandomizeFee(tx.gasprice);
        uint256 usedFunds = WITNET.randomize{value: fee}();

        // Refund dust (should be negligible).
        if (usedFunds < fee) {
            // nothing critical — dust stays in the contract for the next call
        }
    }

    /**
     * @notice Step 2 — Fetch the random seed from Witnet, compute & store the
     *         lottery-compatible result.
     * @dev Must be called after the Witnet oracle has reported the random seed
     *      (typically 5-10 minutes after `getLotteryWinningNumber`).
     *      Anyone can call this (operator, keeper, etc.).
     */
    function fetchAndStoreRandom() external {
        require(latestRandomizingBlock > 0, "No randomize request pending");
        require(randomResult == 0, "Random already fetched");

        // `WITNET.random(range, nonce, blockNumber)` returns a uint32 in [0, range).
        // We use type(uint32).max as the range to get the full uint32 space, then
        // map into [1_000_000, 1_999_999] identically to the old Chainlink approach.
        uint32 rawRandom = WITNET.random(
            type(uint32).max,
            0,
            latestRandomizingBlock
        );

        randomResult = uint32(1000000 + (uint256(rawRandom) % 1000000));
    }

    // ──────────────────────── Admin Setters ────────────────────────

    /**
     * @notice Set the address of the KoanPlayLottery contract.
     */
    function setLotteryAddress(address _koanPlayLottery) external onlyOwner {
        koanPlayLottery = _koanPlayLottery;
    }

    /**
     * @notice Withdraw ERC-20 tokens accidentally sent to this contract.
     */
    function withdrawTokens(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
    }

    /**
     * @notice Withdraw native token (CELO) from this contract.
     */
    function withdrawNative(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    // ──────────────────────── View Helpers ─────────────────────────

    function viewLatestLotteryId() external view returns (uint256) {
        return latestLotteryId;
    }

    function viewRandomResult() external view returns (uint32) {
        return randomResult;
    }

    function setLatestLotteryId(
        uint256 _latestLotteryId
    ) external isLotteryContract {
        latestLotteryId = _latestLotteryId;
    }

    /**
     * @notice Estimate the native token fee required for the next randomize call.
     */
    function estimateFee(uint256 _gasPrice) external view returns (uint256) {
        return WITNET.estimateRandomizeFee(_gasPrice);
    }
}
