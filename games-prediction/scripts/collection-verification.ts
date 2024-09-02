// import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers, getNamedAccounts } from "hardhat";

const madskulz = "0xE652bF1DB28638C61Cc8eEf6177023A2f6243015";
const millady = "0xC8DD8947219308d3237F3C380b7AB24cA5a34e7E";
const feeCollector = "0xE3c347cEa95B7BfdB921074bdb39b8571F905f6D";
const royaltyFees = "2";

const func = async function () {
  //   const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const distantFinance = await ethers.getContract("DistantFinance", deployer);
  console.log("this is deployer", deployer);
  //checks
  console.log("verify protocol contracts", distantFinance.address);
  //   await distantFinance.addCollection(madskulz, feeCollector, royaltyFees);
  //     await distantFinance.verifyCollectionStatus(madskulz, "...")
  //   const collectionDetails = await distantFinance.getCollectionData(madskulz);
  //   console.log(collectionDetails);

  await distantFinance.addCollection(millady, feeCollector, royaltyFees);
  await distantFinance.verifyCollectionStatus(millady, "...");
  const collectionDetails = await distantFinance.getCollectionData(millady);
  console.log(collectionDetails);
};

func();
