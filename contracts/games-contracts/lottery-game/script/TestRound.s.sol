// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {KoanPlayLottery} from "../src/KoanprotocolLottery.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestRound is Script {
    // --- UPDATE THESE ADDRESSES AFTER REDEPLOYMENT ---
    address constant LOTTERY = 0x07305DA0EC4B33236eBEb74588567df3F2B226E4;
    address constant RNG = 0x47495dFF04FCb5DE140b257869Ffe01133BfD865;
    address constant USDC = 0x765DE816845861e75A25fCA122bb6898B8B1282a;

    function run() external {
        uint256 pk = vm.envUint("KEYS");
        vm.startBroadcast(pk);

        KoanPlayLottery lottery = KoanPlayLottery(LOTTERY);
        uint256 currentId = lottery.viewCurrentLotteryId();
        
        // --- Step 1: Start & Buy ---
        // (Uncomment this part for the first run)
        /*
        console2.log("--- Starting Lottery ---");
        uint256 endTime = block.timestamp + 15 minutes;
        uint256[6] memory rewards = [uint256(1000), 1500, 2000, 2500, 1500, 1500];
        lottery.startLottery(endTime, 5e16, 2000, rewards, 1000); // 0.05 USDC price 
        console2.log("Lottery started! ID:", currentId + 1);

        console2.log("--- Buying Tickets ---");
        IERC20(USDC).approve(LOTTERY, type(uint256).max);
        uint32[] memory tickets = new uint32[](3);
        tickets[0] = 1111111;
        tickets[1] = 1222222;
        tickets[2] = 1333333;
        lottery.buyTickets(currentId + 1, tickets);
        console2.log("Tickets bought successfully.");
        */

        // --- Step 2: Close Lottery ---
        // (Uncomment this part after 15 mins)
        /*
        console2.log("--- Closing Lottery ---");
        lottery.closeLottery(currentId);
        console2.log("Closed! Wait 7 mins for Witnet...");
        */

        // --- Step 3: Draw Number ---
        // (Uncomment this part after Witnet is ready)
        /*
        console2.log("--- Drawing Final Number ---");
        RandomNumberGenerator(payable(RNG)).fetchAndStoreRandom();
        lottery.drawFinalNumberAndMakeLotteryClaimable(currentId, false);
        console2.log("Lottery is now CLAIMABLE!");
        */

        vm.stopBroadcast();
    }
}
