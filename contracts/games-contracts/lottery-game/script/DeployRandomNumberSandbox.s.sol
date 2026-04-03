// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {KoanProtocolWitnetRandomnessSandbox} from "../src/RandomNumberSandbox.sol";

contract DeployRandomNumberSandbox is Script {
    function run() external {
        uint256 pk = vm.envUint("KEYS");
        
        vm.startBroadcast(pk);
        
        // --- Deployment ---
        // Official Witnet address on Celo Mainnet
        address WITNET_RANDOMNESS = 0xC0FFEE98AD1434aCbDB894BbB752e138c1006fAB;
        
        KoanProtocolWitnetRandomnessSandbox sandbox = new KoanProtocolWitnetRandomnessSandbox(WITNET_RANDOMNESS);
        console2.log("Randomness Sandbox deployed at:", address(sandbox));
        
        // Optional: Pre-fund the sandbox with some CELO for the test fees
        payable(address(sandbox)).transfer(0.5 ether);
        console2.log("Funded with 0.5 CELO.");

        vm.stopBroadcast();
    }
}
