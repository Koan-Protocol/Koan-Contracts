// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {KoanPlayLottery} from "../src/KoanprotocolLottery.sol";
import {IRandomNumberGenerator} from "../src/interfaces/IRandomNumberGenerator.sol";

contract MockERC20 is ERC20 {
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

contract MockRandomNumberGenerator is IRandomNumberGenerator {
    address public lottery;
    uint256 public latestLotteryId;
    uint32 public randomResult;
    uint256 public requestCount;

    modifier onlyLottery() {
        require(msg.sender == lottery, "Only lottery");
        _;
    }

    function setLottery(address lottery_) external {
        lottery = lottery_;
    }

    function setRandomResult(uint32 randomResult_) external {
        randomResult = randomResult_;
    }

    function getLotteryWinningNumber() external onlyLottery {
        requestCount++;
    }

    function viewLatestLotteryId() external view returns (uint256) {
        return latestLotteryId;
    }

    function setLatestLotteryId(uint256 latestLotteryId_) external onlyLottery {
        latestLotteryId = latestLotteryId_;
    }

    function viewRandomResult() external view returns (uint32) {
        return randomResult;
    }
}

contract KoanPlayLotteryTest is Test {
    MockERC20 internal paymentToken;
    MockRandomNumberGenerator internal rng;
    KoanPlayLottery internal lottery;

    address internal operator = makeAddr("operator");
    address internal treasury = makeAddr("treasury");
    address internal injector = makeAddr("injector");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    uint256 internal constant TICKET_PRICE = 1e6; // 1 USDC-style token (6 decimals)
    uint256 internal constant DISCOUNT_DIVISOR = 1000;
    uint256 internal constant TREASURY_FEE = 1000; // 10%

    function setUp() public {
        paymentToken = new MockERC20("Mock USD", "mUSD", 6);
        rng = new MockRandomNumberGenerator();
        lottery = new KoanPlayLottery(address(paymentToken), address(rng));
        rng.setLottery(address(lottery));

        lottery.setOperatorAndTreasuryAndInjectorAddresses(operator, treasury, injector);

        paymentToken.mint(alice, 1_000_000e6);
        paymentToken.mint(bob, 1_000_000e6);
        paymentToken.mint(injector, 1_000_000e6);

        vm.prank(alice);
        paymentToken.approve(address(lottery), type(uint256).max);
        vm.prank(bob);
        paymentToken.approve(address(lottery), type(uint256).max);
        vm.prank(injector);
        paymentToken.approve(address(lottery), type(uint256).max);
    }

    function testStartLotterySetsRoundState() public {
        uint256 endTime = _startDefaultLottery();

        KoanPlayLottery.Lottery memory round = lottery.viewLottery(1);
        assertEq(lottery.viewCurrentLotteryId(), 1);
        assertEq(uint256(round.status), uint256(KoanPlayLottery.Status.Open));
        assertEq(round.endTime, endTime);
        assertEq(round.priceTicketInPaymentToken, TICKET_PRICE);
        assertEq(rng.latestLotteryId(), 1);
    }

    function testStartLotteryRevertsWhenRewardsDoNotSumTo10000() public {
        uint256[6] memory badBreakdown = [uint256(1000), 1000, 1000, 1000, 1000, 1000];

        vm.prank(operator);
        vm.expectRevert(bytes("Rewards must equal 10000"));
        lottery.startLottery(
            block.timestamp + 2 days,
            TICKET_PRICE,
            DISCOUNT_DIVISOR,
            badBreakdown,
            TREASURY_FEE
        );
    }

    function testBuyTicketsUpdatesBalancesAndOwnership() public {
        _startDefaultLottery();

        uint32[] memory ticketNumbers = new uint32[](2);
        ticketNumbers[0] = 1000001;
        ticketNumbers[1] = 1234567;

        uint256 expectedCost =
            lottery.calculateTotalPriceForBulkTickets(DISCOUNT_DIVISOR, TICKET_PRICE, ticketNumbers.length);
        uint256 aliceBefore = paymentToken.balanceOf(alice);

        vm.prank(alice);
        lottery.buyTickets(1, ticketNumbers);

        KoanPlayLottery.Lottery memory round = lottery.viewLottery(1);
        assertEq(paymentToken.balanceOf(alice), aliceBefore - expectedCost);
        assertEq(round.amountCollectedInPaymentToken, expectedCost);

        (uint256[] memory ids, uint32[] memory numbers,, uint256 cursor) =
            lottery.viewUserInfoForLotteryId(alice, 1, 0, 10);
        assertEq(ids.length, 2);
        assertEq(ids[0], 0);
        assertEq(ids[1], 1);
        assertEq(numbers[0], 1000001);
        assertEq(numbers[1], 1234567);
        assertEq(cursor, 2);
    }

    function testBuyTicketsRevertsForNumberOutsideRange() public {
        _startDefaultLottery();

        uint32[] memory ticketNumbers = new uint32[](1);
        ticketNumbers[0] = 999999;

        vm.prank(alice);
        vm.expectRevert(bytes("Outside range"));
        lottery.buyTickets(1, ticketNumbers);
    }

    function testCloseAndDrawSetsClaimableAndDistributesTreasury() public {
        uint256 endTime = _startDefaultLottery();

        uint32[] memory ticketNumbers = new uint32[](1);
        ticketNumbers[0] = 1234567;

        vm.prank(alice);
        lottery.buyTickets(1, ticketNumbers);

        uint256 treasuryBefore = paymentToken.balanceOf(treasury);

        vm.warp(endTime + 1);
        vm.prank(operator);
        lottery.closeLottery(1);

        rng.setRandomResult(1234567);

        vm.prank(operator);
        lottery.drawFinalNumberAndMakeLotteryClaimable(1, false);

        KoanPlayLottery.Lottery memory round = lottery.viewLottery(1);
        assertEq(uint256(round.status), uint256(KoanPlayLottery.Status.Claimable));
        assertEq(round.finalNumber, 1234567);
        assertEq(round.countWinnersPerBracket[5], 1);

        uint256 amountToShare = (round.amountCollectedInPaymentToken * (10_000 - TREASURY_FEE)) / 10_000;
        uint256 expectedWinnerReward = (round.rewardsBreakdown[5] * amountToShare) / 10_000;
        uint256 expectedTreasuryGain = round.amountCollectedInPaymentToken - expectedWinnerReward;
        assertEq(paymentToken.balanceOf(treasury), treasuryBefore + expectedTreasuryGain);
    }

    function testClaimTicketsTransfersPrizeAndMarksClaimed() public {
        uint256 endTime = _startDefaultLottery();

        uint32[] memory aliceTicket = new uint32[](1);
        aliceTicket[0] = 1234567;
        vm.prank(alice);
        lottery.buyTickets(1, aliceTicket);

        uint32[] memory bobTicket = new uint32[](1);
        bobTicket[0] = 1999999;
        vm.prank(bob);
        lottery.buyTickets(1, bobTicket);

        vm.warp(endTime + 1);
        vm.prank(operator);
        lottery.closeLottery(1);
        rng.setRandomResult(1234567);
        vm.prank(operator);
        lottery.drawFinalNumberAndMakeLotteryClaimable(1, false);

        uint256 reward = lottery.viewRewardsForTicketId(1, 0, 5);
        uint256 aliceBefore = paymentToken.balanceOf(alice);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;
        uint32[] memory brackets = new uint32[](1);
        brackets[0] = 5;

        vm.prank(alice);
        lottery.claimTickets(1, ids, brackets);

        assertEq(paymentToken.balanceOf(alice), aliceBefore + reward);
        (, bool[] memory statuses) = lottery.viewNumbersAndStatusesForTicketIds(ids);
        assertTrue(statuses[0]);
    }

    function testClaimRevertsWhenLowerBracketIsUsedForHigherWinner() public {
        uint256 endTime = _startLotteryWithBracket4And5Winners();

        vm.warp(endTime + 1);
        vm.prank(operator);
        lottery.closeLottery(1);
        rng.setRandomResult(1234567);
        vm.prank(operator);
        lottery.drawFinalNumberAndMakeLotteryClaimable(1, false);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 0; // Alice's exact-match ticket
        uint32[] memory brackets = new uint32[](1);
        brackets[0] = 4;

        vm.prank(alice);
        vm.expectRevert(bytes("Bracket must be higher"));
        lottery.claimTickets(1, ids, brackets);
    }

    function testInjectFundsByInjectorIncreasesPot() public {
        _startDefaultLottery();

        uint256 amount = 250e6;
        vm.prank(injector);
        lottery.injectFunds(1, amount);

        KoanPlayLottery.Lottery memory round = lottery.viewLottery(1);
        assertEq(round.amountCollectedInPaymentToken, amount);
    }

    function testOnlyOwnerCanSetOperatorTreasuryInjector() public {
        vm.prank(alice);
        vm.expectRevert();
        lottery.setOperatorAndTreasuryAndInjectorAddresses(operator, treasury, injector);
    }

    function testUserCanClaimOldRoundAfterSeveralNewRounds() public {
        // Round 1: Alice buys an exact-match ticket
        uint256 endTimeRound1 = _startDefaultLottery();
        uint32[] memory round1Tickets = new uint32[](1);
        round1Tickets[0] = 1234567;

        vm.prank(alice);
        lottery.buyTickets(1, round1Tickets);

        vm.warp(endTimeRound1 + 1);
        vm.prank(operator);
        lottery.closeLottery(1);
        rng.setRandomResult(1234567);
        vm.prank(operator);
        lottery.drawFinalNumberAndMakeLotteryClaimable(1, false);

        uint256 round1Reward = lottery.viewRewardsForTicketId(1, 0, 5);
        assertGt(round1Reward, 0);

        // Round 2
        uint256 endTimeRound2 = _startDefaultLottery();
        vm.warp(endTimeRound2 + 1);
        vm.prank(operator);
        lottery.closeLottery(2);
        rng.setRandomResult(1111111);
        vm.prank(operator);
        lottery.drawFinalNumberAndMakeLotteryClaimable(2, false);

        // Round 3
        uint256 endTimeRound3 = _startDefaultLottery();
        vm.warp(endTimeRound3 + 1);
        vm.prank(operator);
        lottery.closeLottery(3);
        rng.setRandomResult(1222222);
        vm.prank(operator);
        lottery.drawFinalNumberAndMakeLotteryClaimable(3, false);

        // Alice claims from old round 1 after rounds 2 and 3 have passed
        uint256 aliceBefore = paymentToken.balanceOf(alice);
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;
        uint32[] memory brackets = new uint32[](1);
        brackets[0] = 5;

        vm.prank(alice);
        lottery.claimTickets(1, ids, brackets);

        assertEq(paymentToken.balanceOf(alice), aliceBefore + round1Reward);
        (, bool[] memory statuses) = lottery.viewNumbersAndStatusesForTicketIds(ids);
        assertTrue(statuses[0]);
    }

    function _startDefaultLottery() internal returns (uint256 endTime) {
        endTime = block.timestamp + 2 days;
        uint256[6] memory rewards = _defaultRewards();
        vm.prank(operator);
        lottery.startLottery(endTime, TICKET_PRICE, DISCOUNT_DIVISOR, rewards, TREASURY_FEE);
    }

    function _startLotteryWithBracket4And5Winners() internal returns (uint256 endTime) {
        endTime = _startDefaultLottery();

        // Exact winner
        uint32[] memory aliceTicket = new uint32[](1);
        aliceTicket[0] = 1234567;
        vm.prank(alice);
        lottery.buyTickets(1, aliceTicket);

        // Same last 5 digits only
        uint32[] memory bobTicket = new uint32[](1);
        bobTicket[0] = 1134567;
        vm.prank(bob);
        lottery.buyTickets(1, bobTicket);
    }

    function _defaultRewards() internal pure returns (uint256[6] memory) {
        return [uint256(500), 1000, 1500, 2000, 2500, 2500];
    }
}
