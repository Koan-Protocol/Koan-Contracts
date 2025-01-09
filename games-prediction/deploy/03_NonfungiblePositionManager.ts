import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";

// always update for deployments

import corecontracts from "../../deployments/v3core/sepolia_11155111.json";

const func: DeployFunction = async function ({
  // ethers,
  getNamedAccounts,
  deployments,
  getChainId,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const chainId = await getChainId();

  const WETH_SEPOLIA = "0xe8188160f0b8E4A2940A6B9779ed0FE9A2506dF7";

  if (!deployments.get("NonfungibleTokenPositionDescriptor")) {
    throw Error(`No NonfungibleTokenPositionDescriptor for chain #${chainId}!`);
  }

  const NonfungibleTokenPositionDescriptor = await deployments.get("NonfungibleTokenPositionDescriptor");

  await deploy("NonfungiblePositionManager", {
    from: deployer,
    args: [corecontracts.UniswapV3Factory, WETH_SEPOLIA, NonfungibleTokenPositionDescriptor.address],
    log: true,
    deterministicDeployment: false,
  });
};

func.tags = ["NonfungiblePositionManager"];

func.dependencies = ["NonfungibleTokenPositionDescriptor"];

export default func;
