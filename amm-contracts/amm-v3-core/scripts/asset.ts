// import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers } from "hardhat";

const assetscooperAbi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "aggregationRouterV6",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "message",
        type: "string",
      },
    ],
    name: "EmptyData",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "message",
        type: "string",
      },
    ],
    name: "InsufficientOutputAmount",
    type: "error",
  },
  {
    inputs: [],
    name: "InvalidSelector",
    type: "error",
  },
  {
    inputs: [],
    name: "Reentrancy",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "message",
        type: "string",
      },
    ],
    name: "UnsuccessfulSwap",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "dstToken",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "amountOut",
        type: "uint256",
      },
    ],
    name: "SwapExecuted",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address[]",
        name: "tokenAddresses",
        type: "address[]",
      },
      {
        internalType: "uint256[]",
        name: "amounts",
        type: "uint256[]",
      },
    ],
    name: "approveAll",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "i_AggregationRouter_V6",
    outputs: [
      {
        internalType: "contract IAggregationRouterV6",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "minAmountOut",
        type: "uint256",
      },
      {
        internalType: "bytes[]",
        name: "data",
        type: "bytes[]",
      },
    ],
    name: "swap",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const swapData = [
  "0x07ed2379000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd0900000000000000000000000050c5725949a6f0c72e6c4a641f24049a917db0cb0000000000000000000000004200000000000000000000000000000000000006000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd09000000000000000000000000e3c347cea95b7bfdb921074bdb39b8571f905f6d00000000000000000000000000000000000000000000000008ed5bf8582fb424000000000000000000000000000000000000000000000000000054fbc7e9c87d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000af00000000000000000000000000000000000000000000000000009100006302a0000000000000000000000000000000000000000000000000000054fbc7e9c87dee63c1e58093e8542e6ca0efffb9d57a270b76712b968a38f550c5725949a6f0c72e6c4a641f24049a917db0cb111111125421ca6dc452d289314280a0f8842a650020d6bdbf784200000000000000000000000000000000000006111111125421ca6dc452d289314280a0f8842a650000000000000000000000000000000000b3e5ee25",
];
const assetscooperContract = "0x7D2F2cadf94B7f201164388a2E617a76533a0281";
const func = async function () {
  const provider = new ethers.providers.JsonRpcProvider(process.env.ALCHEMY_PROVIDER!);
  const wallet = new ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY!, provider);

  const assetscooperContractInstance = new ethers.Contract(assetscooperContract, assetscooperAbi, wallet);

  const swap = await assetscooperContractInstance.swap(0, swapData);

  console.log("swapfinished", swap);
};

func();
