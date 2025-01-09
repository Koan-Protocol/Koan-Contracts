import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import config from "../config";

const func: DeployFunction = async function ({
  // ethers,
  getNamedAccounts,
  deployments,
  network,
}: // getChainId,
HardhatRuntimeEnvironment) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  // Get network data from Hardhat config (see hardhat.config.ts).
  const networkName = network.name;

  // Check if the addresses in the config are set.

  if (
    config.Address.Token[networkName] === ethers.constants.AddressZero ||
    config.Address.Oracle[networkName] === ethers.constants.AddressZero ||
    config.Address.Admin[networkName] === ethers.constants.AddressZero ||
    config.Address.Operator[networkName] === ethers.constants.AddressZero
  ) {
    throw new Error("Missing addresses (Chainlink Oracle and/or Admin/Operator)");
  }

  await deploy("KoanprotocolPrediction", {
    from: deployer,
    args: [
      config.Address.Token[networkName],
      config.Address.Oracle[networkName],
      config.Address.Admin[networkName],
      config.Address.Operator[networkName],
      config.Block.Interval[networkName],
      config.Block.Buffer[networkName],
      parseEther(config.BetAmount[networkName].toString()).toString(),
      config.OracleUpdateAllowance[networkName],
      config.Treasury[networkName],
    ],
    log: true,
    deterministicDeployment: false,
  });
};

func.tags = ["KoanprotocolPrediction"];

export default func;
