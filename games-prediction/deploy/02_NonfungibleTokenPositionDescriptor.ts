import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";

const func: DeployFunction = async function ({ ethers, getNamedAccounts, deployments }: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  // const chainId = await getChainId();
  const WETH_SEPOLIA = "0xe8188160f0b8E4A2940A6B9779ed0FE9A2506dF7";

  function isAscii(str: string): boolean {
    return /^[\x00-\x7F]*$/.test(str);
  }
  function asciiStringToBytes32(str: string): string {
    if (str.length > 32 || !isAscii(str)) {
      throw new Error("Invalid label, must be less than 32 characters");
    }

    return "0x" + Buffer.from(str, "ascii").toString("hex").padEnd(64, "0");
  }

  const NFTDescriptor = await deployments.get("NFTDescriptor");

  const nativeCurrencyLabelBytes = ethers.utils.formatBytes32String("ETH");

  console.log(
    "Deploying NonfungibleTokenPositionDescriptor... ",
    "native label byte",
    nativeCurrencyLabelBytes,
    NFTDescriptor.address,
    {
      args: [WETH_SEPOLIA, asciiStringToBytes32("ETH")],
    },
  );

  await deploy("NonfungibleTokenPositionDescriptor", {
    from: deployer,
    args: [WETH_SEPOLIA, asciiStringToBytes32("ETH")],
    log: true,
    deterministicDeployment: false,
    libraries: {
      NFTDescriptor: NFTDescriptor.address,
    },
  });
};

func.tags = ["NonfungibleTokenPositionDescriptor"];

func.dependencies = ["NFTDescriptor"];

export default func;
