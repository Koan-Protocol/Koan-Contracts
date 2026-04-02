// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {KoanPlayLottery} from "../src/KoanprotocolLottery.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract DeployLottery is Script {
    function run() external {
        // Load private key from .env file (as defined in your local KEYS variable)
        uint256 deployerPrivateKey = vm.envUint("KEYS");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console2.log("Deploying contracts with address:", deployerAddress);

        // --- Celo Mainnet Parameters ---
        // Official Witnet address on Celo Mainnet
        address WITNET_RANDOMNESS = 0xC0FFEE98AD1434aCbDB894BbB752e138c1006fAB;
        // Native USDC on Celo
        address USDC_CELO = 0x765DE816845861e75A25fCA122bb6898B8B1282a;

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy RandomNumberGenerator
        RandomNumberGenerator rng = new RandomNumberGenerator(WITNET_RANDOMNESS);
        console2.log("RandomNumberGenerator deployed at:", address(rng));

        // 2. Deploy KoanPlayLottery
        KoanPlayLottery lottery = new KoanPlayLottery(USDC_CELO, address(rng));
        console2.log("KoanPlayLottery deployed at:", address(lottery));

        // 3. Configure contracts
        rng.setLotteryAddress(address(lottery));
        console2.log("RNG linked to lottery.");

        // Set operator/treasury/injector to the deployer by default
        lottery.setOperatorAndTreasuryAndInjectorAddresses(
            deployerAddress,
            deployerAddress, 
            deployerAddress
        );
        console2.log("Lottery roles configured (operator/treasury/injector => deployer).");

        vm.stopBroadcast();
    }
}
