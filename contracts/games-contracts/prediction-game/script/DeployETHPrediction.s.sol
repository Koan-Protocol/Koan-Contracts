// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {KoanprotocolPrediction} from "../src/KoanprotocolPrediction.sol";

contract DeployETHPrediction is Script {
    // ============ BASE MAINNET ADDRESSES ============
    // Chainlink ETH/USD Price Feed on Base Mainnet (Standard Proxy)
    address constant ETH_USD_ORACLE =
        0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;

    // ============ DEPLOYMENT PARAMETERS ============
    // Recommended parameters for ETH prediction game
    uint256 constant INTERVAL_SECONDS = 300; // 5 minutes per round
    uint256 constant BUFFER_SECONDS = 30; // 30 seconds buffer for resolution
    uint256 constant MIN_BET_AMOUNT = 100000; // 0.1 USDC (6 decimals)
    uint256 constant ORACLE_UPDATE_ALLOWANCE = 300; // 5 minutes
    uint256 constant TREASURY_FEE = 300; // 3%

    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address predictionToken = vm.envAddress("PREDICTION_TOKEN");
        address adminAddress = vm.envAddress("ADMIN_ADDRESS");
        address operatorAddress = vm.envAddress("OPERATOR_ADDRESS");

        console.log(
            "=== Deploying KoanprotocolPrediction for ETH/USD on Base Mainnet ==="
        );
        console.log("Prediction Token:", predictionToken);
        console.log("ETH/USD Oracle:", ETH_USD_ORACLE);
        console.log("Admin:", adminAddress);
        console.log("Operator:", operatorAddress);
        console.log("Interval:", INTERVAL_SECONDS, "seconds");
        console.log("Buffer:", BUFFER_SECONDS, "seconds");
        console.log("Min Bet:", MIN_BET_AMOUNT, "(0.1 USDC)");
        console.log("Treasury Fee:", TREASURY_FEE, "(3%)");

        vm.startBroadcast(deployerPrivateKey);

        KoanprotocolPrediction prediction = new KoanprotocolPrediction(
            predictionToken,
            ETH_USD_ORACLE,
            adminAddress,
            operatorAddress,
            INTERVAL_SECONDS,
            BUFFER_SECONDS,
            MIN_BET_AMOUNT,
            ORACLE_UPDATE_ALLOWANCE,
            TREASURY_FEE
        );

        console.log("=== Deployment Complete ===");
        console.log(
            "KoanprotocolPrediction (ETH/USD) deployed at:",
            address(prediction)
        );

        vm.stopBroadcast();
    }
}
