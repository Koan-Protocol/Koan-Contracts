import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";

// always update for deployments

import corecontracts from "../../deployments/v3core/sepolia_11155111.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, getChainId } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  if (!process.env.WNATIVE_ADDRESS) {
    throw Error(`No WNATIVE_ADDRESS for chain #${chainId}!`);
  }

  if (!process.env.FACTORY_ADDRESS) {
    throw Error(`No FACTORY_ADDRESS for chain #${chainId}!`);
  }

  const swapRouterArtifact = await hre.artifacts.readArtifact("SwapRouter");

  await deploy("SwapRouter", {
    from: deployer,
    contract: {
      bytecode: swapRouterArtifact.bytecode,
      abi: swapRouterArtifact.abi,
    },
    args: [corecontracts.UniswapV3Factory, process.env.WNATIVE_ADDRESS],
    log: true,
    deterministicDeployment: false,
  });
};

export default func;
func.tags = ["SwapRouter"];
