// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {KoanProtocolWitnetRandomnessSandbox} from "../src/RandomNumberSandbox.sol";

contract SandboxTest is Script {
    function run() external {
        uint256 pk = vm.envUint("KEYS");
        address deployer = vm.addr(pk);
        
        vm.startBroadcast(pk);
        
        // --- Deployment ---
        // Official Witnet address on Celo Mainnet
        address WITNET_RANDOMNESS = 0xC0FFEE98AD1434aCbDB894BbB752e138c1006fAB;
        
        KoanProtocolWitnetRandomnessSandbox sandbox = new KoanProtocolWitnetRandomnessSandbox(WITNET_RANDOMNESS);
        console2.log("Sandbox deployed at:", address(sandbox));
        
        // --- Funding ---
        // Send 0.5 CELO for Witnet fees
        console2.log("Funding sandbox with 0.5 CELO...");
        payable(address(sandbox)).transfer(0.5 ether);

        // --- Step 1: Request Random ---
        console2.log("Requesting random number...");
        sandbox.requestRandomNumber();
        console2.log("Requested! Block:", block.number);
        console2.log("--------------------------------------------------");
        console2.log("Wait 5-10 minutes, then run the FETCH command.");
        console2.log("--------------------------------------------------");

        vm.stopBroadcast();
    }
}
