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
  const SwapRouter = await deployments.get("SwapRouter");
  const NFTDescriptor = await deployments.get("NFTDescriptor");
  const NonfungibleTokenPositionDescriptor = await deployments.get("NonfungibleTokenPositionDescriptor");
  const NonfungiblePositionManager = await deployments.get("NonfungiblePositionManager");
  const UniswapInterfaceMulticall = await deployments.get("UniswapInterfaceMulticall");
  const V3Migrator = await deployments.get("V3Migrator");
  const TickLens = await deployments.get("TickLens");
  const QuoterV2 = await deployments.get("QuoterV2");

  const contracts = {
    SwapRouter: SwapRouter.address,
    NFTDescriptor: NFTDescriptor.address,
    NonfungibleTokenPositionDescriptor: NonfungibleTokenPositionDescriptor.address,
    NonfungiblePositionManager: NonfungiblePositionManager.address,
    UniswapInterfaceMulticall: UniswapInterfaceMulticall.address,
    V3Migrator: V3Migrator.address,
    TickLens: TickLens.address,
    QuoterV2: QuoterV2.address,
  };

  fs.writeFileSync(
    `../deployments/v3periphery/${network.name + "_" + chainId}.json`,
    JSON.stringify(contracts, null, 2),
  );
};

export default func;
func.tags = ["Updater.."];
