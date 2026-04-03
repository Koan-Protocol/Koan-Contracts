// import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers, getNamedAccounts } from "hardhat";

const P2PLENDING = "0xe92c6c2bf27d9d929091db016104397cfc247292";
const millady = "0xC8DD8947219308d3237F3C380b7AB24cA5a34e7E";

const tokenIds = [3];
const amountToBorrow = "1000000000000000000";
const expiryInDays = 10;
const interestToPay = 200;

const abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_collection",
        type: "address",
      },
      {
        internalType: "uint256[]",
        name: "_tokens",
        type: "uint256[]",
      },
      {
        internalType: "uint256",
        name: "_amountToBorrow",
        type: "uint256",
      },
      {
        internalType: "uint8",
        name: "_expiryInDays",
        type: "uint8",
      },
      {
        internalType: "uint16",
        name: "_interestToPay",
        type: "uint16",
      },
    ],
    name: "openContract",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const func = async function () {
  const provider = new ethers.providers.JsonRpcProvider(process.env.ALCHEMY_PROVIDER!);
  const wallet = new ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY!, provider);

  const p2plendingContract = new ethers.Contract(P2PLENDING, abi, wallet);

  // await p2plendingContract.openContract(millady, tokenIds, amountToBorrow, expiryInDays, interestToPay);

  const userActiveLoan = await p2plendingContract.getUserActiveLoanIds(wallet.address);
  console.log(userActiveLoan);
};

func();
