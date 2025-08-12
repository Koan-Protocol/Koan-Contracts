import * as dotenv from "dotenv";
dotenv.config();
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-verify";

const providerApiKey = process.env.ALCHEMY_API_KEY || "oKxs-03sij-U_N0iOlrSsZFr29-IqbuF";
const deployerPrivateKey = process.env.DEPLOYER_PRIVATE_KEY;
// const etherscanApiKey = process.env.ETHERSCAN_API_KEY;
const basescanApiKey = process.env.BASESCAN_API_KEY;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.7.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 800,
      },
      metadata: {
        // do not include the metadata hash, since this is machine dependent
        // and we want all generated code to be deterministic
        // https://docs.soliditylang.org/en/v0.7.6/metadata.html
        bytecodeHash: "none",
      },
    },
  },
  defaultNetwork: "lisk-sepolia",
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
    "lisk-sepolia": {
      url: "https://rpc.sepolia-api.lisk.com",
      accounts: [deployerPrivateKey!],
      gasPrice: 1000000000,
      verify: {
        etherscan: {
          apiKey: "123",
          apiUrl: "https://sepolia-blockscout.lisk.com/api",
        },
      },
    },
    lisk: {
      url: "https://rpc.api.lisk.com",
      accounts: [deployerPrivateKey!],
      gasPrice: 1000000000,
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey!],
    },
  },
  verify: {
    etherscan: {
      // apiKey: `${etherscanApiKey}`,
      apiKey: "123",
    },
  },
};

export default config;
