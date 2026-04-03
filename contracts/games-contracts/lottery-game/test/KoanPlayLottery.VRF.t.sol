// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {KoanPlayLottery} from "../src/KoanprotocolLottery.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";
import {MockWitnetRandomness} from "./mocks/MockWitnetRandomness.sol";

contract MockERC20Witnet is ERC20 {
    uint8 private immutable _TOKEN_DECIMALS;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _TOKEN_DECIMALS = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _TOKEN_DECIMALS;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title KoanPlayLotteryWitnetIntegrationTest
 * @notice End-to-end integration test exercising the real RandomNumberGenerator
 *         contract (Witnet-based) against the MockWitnetRandomness oracle.
 *
 *  Flow exercised per test:
 *   1. Start lottery
 *   2. Buy tickets
 *   3. Warp past endTime → operator calls closeLottery()
 *        → RNG calls witnet.randomize()
 *   4. Test simulates oracle response via mock.setRandomnessResult()
 *   5. Anyone calls rng.fetchAndStoreRandom()
 *   6. Operator calls drawFinalNumberAndMakeLotteryClaimable()
 *   7. Verify state, claim prizes
 */
contract KoanPlayLotteryWitnetIntegrationTest is Test {
    MockERC20Witnet internal paymentToken;
    MockWitnetRandomness internal mockWitnet;
    RandomNumberGenerator internal rng;
    KoanPlayLottery internal lottery;

    address internal operator = makeAddr("operator");
    address internal treasury = makeAddr("treasury");
    address internal injector = makeAddr("injector");
    address internal alice = makeAddr("alice");

    uint256 internal constant TICKET_PRICE = 1e6;
    uint256 internal constant DISCOUNT_DIVISOR = 1000;
    uint256 internal constant TREASURY_FEE = 1000;

    function setUp() public {
        paymentToken = new MockERC20Witnet("Mock USD", "mUSD", 6);

        // Deploy mock Witnet oracle
        mockWitnet = new MockWitnetRandomness();

        // Deploy the real RandomNumberGenerator with the mock oracle
        rng = new RandomNumberGenerator(address(mockWitnet));

        // Deploy lottery
        lottery = new KoanPlayLottery(address(paymentToken), address(rng));

        // Wire up
        lottery.setOperatorAndTreasuryAndInjectorAddresses(operator, treasury, injector);
        rng.setLotteryAddress(address(lottery));

        // Fund
        paymentToken.mint(alice, 1_000_000e6);
        vm.prank(alice);
        paymentToken.approve(address(lottery), type(uint256).max);
    }

    function testWitnetMockCanFulfillAndDriveLotteryClaimable() public {
        uint256 endTime = _startDefaultLottery();

        // Alice buys ticket 1234567
        uint32[] memory tickets = new uint32[](1);
        tickets[0] = 1234567;
        vm.prank(alice);
        lottery.buyTickets(1, tickets);

        // Warp past end time
        vm.warp(endTime + 1);

        // Record the block number before closing (closeLottery will call
        // rng.getLotteryWinningNumber which calls witnet.randomize)
        uint256 randomizeBlock = block.number;

        vm.prank(operator);
        lottery.closeLottery(1);

        // Verify the RNG recorded the randomizing block
        assertEq(rng.latestRandomizingBlock(), randomizeBlock);
        // randomResult should be 0 (not yet fetched)
        assertEq(rng.viewRandomResult(), 0);

        // Simulate Witnet oracle reporting. We want finalNumber = 1234567.
        // The RNG does: randomResult = 1_000_000 + (rawRandom % 1_000_000)
        // So rawRandom % 1_000_000 must equal 234_567.
        // We pass 234_567 directly as the raw result.
        mockWitnet.setRandomnessResult(randomizeBlock, 234567);

        // Step 2: fetch the random result
        rng.fetchAndStoreRandom();
        assertEq(rng.viewRandomResult(), 1234567);

        // Draw the final number
        vm.prank(operator);
        lottery.drawFinalNumberAndMakeLotteryClaimable(1, false);

        // Verify lottery state
        KoanPlayLottery.Lottery memory round = lottery.viewLottery(1);
        assertEq(uint256(round.status), uint256(KoanPlayLottery.Status.Claimable));
        assertEq(round.finalNumber, 1234567);
        assertEq(round.countWinnersPerBracket[5], 1);
    }

    function testFetchRevertsBeforeOracleReportsResult() public {
        uint256 endTime = _startDefaultLottery();

        uint32[] memory tickets = new uint32[](1);
        tickets[0] = 1234567;
        vm.prank(alice);
        lottery.buyTickets(1, tickets);

        vm.warp(endTime + 1);
        vm.prank(operator);
        lottery.closeLottery(1);

        // Do NOT call mockWitnet.setRandomnessResult(...)
        // fetchAndStoreRandom should revert because the oracle hasn't reported
        vm.expectRevert("MockWitnet: not yet randomized");
        rng.fetchAndStoreRandom();
    }

    function testCannotFetchTwice() public {
        uint256 endTime = _startDefaultLottery();

        uint32[] memory tickets = new uint32[](1);
        tickets[0] = 1234567;
        vm.prank(alice);
        lottery.buyTickets(1, tickets);

        vm.warp(endTime + 1);

        uint256 randomizeBlock = block.number;
        vm.prank(operator);
        lottery.closeLottery(1);

        mockWitnet.setRandomnessResult(randomizeBlock, 234567);
        rng.fetchAndStoreRandom();

        // Second fetch should revert
        vm.expectRevert("Random already fetched");
        rng.fetchAndStoreRandom();
    }

    function testFullFlowWithClaimAndMultipleRounds() public {
        // ── Round 1 ──
        uint256 endTime1 = _startDefaultLottery();

        uint32[] memory tickets1 = new uint32[](1);
        tickets1[0] = 1555555;
        vm.prank(alice);
        lottery.buyTickets(1, tickets1);

        vm.warp(endTime1 + 1);
        uint256 block1 = block.number;
        vm.prank(operator);
        lottery.closeLottery(1);

        // Oracle reports: we want finalNumber = 1555555
        // rawRandom % 1_000_000 = 555_555
        mockWitnet.setRandomnessResult(block1, 555555);
        rng.fetchAndStoreRandom();
        assertEq(rng.viewRandomResult(), 1555555);

        vm.prank(operator);
        lottery.drawFinalNumberAndMakeLotteryClaimable(1, false);

        // Alice claims bracket 5 (exact match)
        uint256 reward = lottery.viewRewardsForTicketId(1, 0, 5);
        assertGt(reward, 0);

        uint256 aliceBefore = paymentToken.balanceOf(alice);
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;
        uint32[] memory brackets = new uint32[](1);
        brackets[0] = 5;

        vm.prank(alice);
        lottery.claimTickets(1, ids, brackets);
        assertEq(paymentToken.balanceOf(alice), aliceBefore + reward);

        // ── Round 2 ──
        uint256 endTime2 = _startDefaultLottery();
        vm.warp(endTime2 + 1);
        uint256 block2 = block.number;
        vm.prank(operator);
        lottery.closeLottery(2);

        mockWitnet.setRandomnessResult(block2, 111111);
        rng.fetchAndStoreRandom();

        vm.prank(operator);
        lottery.drawFinalNumberAndMakeLotteryClaimable(2, false);

        KoanPlayLottery.Lottery memory round2 = lottery.viewLottery(2);
        assertEq(uint256(round2.status), uint256(KoanPlayLottery.Status.Claimable));
        assertEq(round2.finalNumber, 1111111);
    }

    function testEstimateFeeReturnsOracleFee() public {
        mockWitnet.setMockFee(0.01 ether);
        assertEq(rng.estimateFee(20 gwei), 0.01 ether);
    }

    function _startDefaultLottery() internal returns (uint256 endTime) {
        endTime = block.timestamp + 2 days;
        uint256[6] memory rewards = [uint256(500), 1000, 1500, 2000, 2500, 2500];
        vm.prank(operator);
        lottery.startLottery(endTime, TICKET_PRICE, DISCOUNT_DIVISOR, rewards, TREASURY_FEE);
    }
}
