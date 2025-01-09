import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";

// always update for deployments

import corecontracts from "../../deployments/v3core/sepolia_11155111.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  // const chainId = await getChainId();

  const WETH_SEPOLIA = "0xe8188160f0b8E4A2940A6B9779ed0FE9A2506dF7";

  const v3Migrator = await hre.artifacts.readArtifact("V3Migrator");
  const NonfungiblePositionManager = await deployments.get("NonfungiblePositionManager");
  await deploy("V3Migrator", {
    from: deployer,
    contract: {
      bytecode: v3Migrator.bytecode,
      abi: v3Migrator.abi,
    },
    args: [corecontracts.UniswapV3Factory, WETH_SEPOLIA, NonfungiblePositionManager.address],
    log: true,
    deterministicDeployment: false,
  });
};

export default func;
func.tags = ["V3Migrator"];
