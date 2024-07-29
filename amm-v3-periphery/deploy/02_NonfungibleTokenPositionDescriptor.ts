import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";

const func: DeployFunction = async function ({
  ethers,
  getNamedAccounts,
  deployments,
  getChainId,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const chainId = await getChainId();

  if (!process.env.WNATIVE_ADDRESS) {
    throw Error(`No WNATIVE_ADDRESS for chain #${chainId}!`);
  }

  if (!process.env.NATIVE_CURRENCY_LABEL) {
    throw Error(`No NATIVE_CURRENCY_LABEL for chain #${chainId}!`);
  }

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

  const nativeCurrencyLabelBytes = ethers.utils.formatBytes32String(process.env.NATIVE_CURRENCY_LABEL);

  console.log(
    "Deploying NonfungibleTokenPositionDescriptor... ",
    "native label byte",
    nativeCurrencyLabelBytes,
    NFTDescriptor.address,
    {
      args: [process.env.WNATIVE_ADDRESS, asciiStringToBytes32("ETH")],
    },
  );

  await deploy("NonfungibleTokenPositionDescriptor", {
    from: deployer,
    args: [process.env.WNATIVE_ADDRESS, asciiStringToBytes32("ETH")],
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
