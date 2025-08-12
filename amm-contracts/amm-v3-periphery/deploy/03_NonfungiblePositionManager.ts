import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";

// always update for deployments

// import corecontracts from "../../deployments/v3core/sepolia_11155111.json";

// const FACTORY_ADDRESS = "0x4E02A5e71197fAE4925b23CEdc35D987a4409DB0";
const FACTORY_ADDRESS = "0xbdf65e7100B459d402b714c25CbeAB5b4CB4dDc2";
const WNATIVE_ADDRESS = "0x4200000000000000000000000000000000000006";

const func: DeployFunction = async function ({
  // ethers,
  getNamedAccounts,
  deployments,
  getChainId,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const chainId = await getChainId();

  // if (!process.env.WNATIVE_ADDRESS) {
  //   throw Error(`No WNATIVE_ADDRESS for chain #${chainId}!`);
  // }

  // const WETH_SEPOLIA = "0xe8188160f0b8E4A2940A6B9779ed0FE9A2506dF7";

  if (!deployments.get("NonfungibleTokenPositionDescriptor")) {
    throw Error(`No NonfungibleTokenPositionDescriptor for chain #${chainId}!`);
  }

  const NonfungibleTokenPositionDescriptor = await deployments.get("NonfungibleTokenPositionDescriptor");

  await deploy("NonfungiblePositionManager", {
    from: deployer,
    args: [FACTORY_ADDRESS, WNATIVE_ADDRESS, NonfungibleTokenPositionDescriptor.address],
    log: true,
    deterministicDeployment: false,
  });
};

func.tags = ["NonfungiblePositionManager"];

func.dependencies = ["NonfungibleTokenPositionDescriptor"];

export default func;
