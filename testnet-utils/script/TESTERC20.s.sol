// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {TESTERC20} from "../src/TESTERC20.sol";
import {console2} from "forge-std/console2.sol";


contract DeployERC20 is Script {
    function run() external returns (TESTERC20) {

        uint256 TOTAL_SUPPLY = 1_000_000_000 ether;
        // Get deployment private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        TESTERC20 token = new TESTERC20(
            TOTAL_SUPPLY,
            "Test Token", // name
            "TEST" // symbol
        );

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log the deployment
        console2.log("Token deployed to:", address(token));
        console2.log("Owner address:", vm.addr(deployerPrivateKey));

        return token;
    }
}
