import * as dotenv from "dotenv";
dotenv.config();
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-verify";

const LOW_OPTIMIZER_COMPILER_SETTINGS = {
  version: "0.7.6",
  settings: {
    evmVersion: "istanbul",
    optimizer: {
      enabled: true,
      runs: 2_000,
    },
    metadata: {
      bytecodeHash: "none",
    },
  },
};

const LOWEST_OPTIMIZER_COMPILER_SETTINGS = {
  version: "0.7.6",
  settings: {
    evmVersion: "istanbul",
    optimizer: {
      enabled: true,
      runs: 1_000,
    },
    metadata: {
      bytecodeHash: "none",
    },
  },
};

const DEFAULT_COMPILER_SETTINGS = {
  version: "0.7.6",
  settings: {
    evmVersion: "istanbul",
    optimizer: {
      enabled: true,
      runs: 1_000_000,
    },
    metadata: {
      bytecodeHash: "none",
    },
  },
};

const providerApiKey = process.env.ALCHEMY_API_KEY || "oKxs-03sij-U_N0iOlrSsZFr29-IqbuF";
const deployerPrivateKey = process.env.DEPLOYER_PRIVATE_KEY;
const etherscanApiKey = process.env.ETHERSCAN_API_KEY;
const basescanApiKey = process.env.BASESCAN_API_KEY;

const config: HardhatUserConfig = {
  solidity: {
    compilers: [DEFAULT_COMPILER_SETTINGS],
    overrides: {
      "contracts/NonfungiblePositionManager.sol": LOW_OPTIMIZER_COMPILER_SETTINGS,
      "contracts/test/MockTimeNonfungiblePositionManager.sol": LOW_OPTIMIZER_COMPILER_SETTINGS,
      "contracts/test/NFTDescriptorTest.sol": LOWEST_OPTIMIZER_COMPILER_SETTINGS,
      "contracts/NonfungibleTokenPositionDescriptor.sol": LOWEST_OPTIMIZER_COMPILER_SETTINGS,
      "contracts/libraries/NFTDescriptor.sol": LOWEST_OPTIMIZER_COMPILER_SETTINGS,
    },
  },
  defaultNetwork: "baseSepolia",
  // defaultNetwork: "hardhat",
  namedAccounts: {
    // deployer: {
    //   default: "0x261386C962c7f035E98C13271218eF5CBD09C47d",
    // },
    // wallet5: {
    //   default: "0xE3c347cEa95B7BfdB921074bdb39b8571F905f6D",
    // },
    deployer: {
      // By default, it will take the first Hardhat account as the deployer
      default: 0,
    },
    alice: {
      default: 1,
    },
    bob: {
      default: 2,
    },
    carol: {
      default: 3,
    },
    dev: {
      default: 4,
    },
    feeTo: {
      default: 5,
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${providerApiKey}`,
        enabled: process.env.MAINNET_FORKING_ENABLED === "true",
      },
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey!],
    },
    "lisk-sepolia": {
      url: "https://rpc.sepolia-api.lisk.com",
      accounts: [deployerPrivateKey!],
      gasPrice: 1000000000,
    },
    lisk: {
      url: "https://rpc.api.lisk.com",
      accounts: [deployerPrivateKey!],
      gasPrice: 1000000000,
    },
    base: {
      url: "https://mainnet.base.org",
      accounts: [deployerPrivateKey!],
      verify: {
        etherscan: {
          apiUrl: "https://api.basescan.org/api",
          apiKey: basescanApiKey,
        },
      },
    },
    baseSepolia: {
      url: "https://sepolia.base.org",
      accounts: [deployerPrivateKey!],
      verify: {
        etherscan: {
          apiUrl: "https://api-sepolia.basescan.org",
          apiKey: basescanApiKey,
        },
      },
    },
  },
  verify: {
    etherscan: {
      apiKey: `${etherscanApiKey}`,
    },
  },
};

export default config;
