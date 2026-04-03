import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import fs from "fs";

const func: DeployFunction = async function ({
  //   ethers,
  //   getNamedAccounts,
  deployments,
  getChainId,
  network,
}: HardhatRuntimeEnvironment) {
  const chainId = await getChainId();
  const UniswapV3Factory = await deployments.get("UniswapV3Factory");

  const contracts = {
    UniswapV3Factory: UniswapV3Factory.address,
  };

  fs.writeFileSync(`../deployments/v3core/${network.name + "_" + chainId}.json`, JSON.stringify(contracts, null, 2));
};

export default func;
func.tags = ["Updater.."];
