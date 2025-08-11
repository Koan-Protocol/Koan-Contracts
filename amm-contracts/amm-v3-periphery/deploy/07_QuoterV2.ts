import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
// import corecontracts from "../../deployments/v3core/baseSepolia_84532.json";

// const FACTORY_ADDRESS = "0x4E02A5e71197fAE4925b23CEdc35D987a4409DB0";
const FACTORY_ADDRESS = "0xbdf65e7100B459d402b714c25CbeAB5b4CB4dDc2";
const WNATIVE_ADDRESS = "0x4200000000000000000000000000000000000006";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, getChainId } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  console.log({ chainId });
  // if (!process.env.WNATIVE_ADDRESS) {
  //   throw Error(`No WNATIVE_ADDRESS for chain #${chainId}!`);
  // }

  // if (!process.env.FACTORY_ADDRESS) {
  //   throw Error(`No FACTORY_ADDRESS for chain #${chainId}!`);
  // }

  const quoterV2Artifact = await hre.artifacts.readArtifact("QuoterV2");

  await deploy("QuoterV2", {
    from: deployer,
    contract: {
      bytecode: quoterV2Artifact.bytecode,
      abi: quoterV2Artifact.abi,
    },
    args: [FACTORY_ADDRESS, WNATIVE_ADDRESS],
    log: true,
    deterministicDeployment: false,
  });
};

export default func;
func.tags = ["QuoterV2"];
