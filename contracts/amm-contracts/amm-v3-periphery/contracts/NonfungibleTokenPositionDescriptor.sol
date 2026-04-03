// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/lib/contracts/libraries/SafeERC20Namer.sol";

import "./libraries/ChainId.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/INonfungibleTokenPositionDescriptor.sol";
import "./interfaces/IERC20Metadata.sol";
import "./libraries/PoolAddress.sol";
import "./libraries/NFTDescriptor.sol";
import "./libraries/TokenRatioSortOrder.sol";

/// @title Describes NFT token positions
/// @notice Produces a string containing the data URI for a JSON metadata string
contract NonfungibleTokenPositionDescriptor is
	INonfungibleTokenPositionDescriptor
{
	address private constant DAI = 0x6b5C3fC0EdB93115dCA94221E6826dAaC296AA9c;
	address private constant USDC = 0x65B02bE3Fa8B6009E513C85887aB4923Ba2A998d;
	address private constant USDT = 0xcD47821BF5096914858e94EDFd4218B6f5Ab3635;
	address private constant TBTC = 0x151e597537d84a1D4E1E8e5f1409846CC15C2446;
	address private constant WBTC = 0xa8773c21db637d4cf87e7E6A05093D0052064957;

	address public immutable WETH9;
	/// @dev A null-terminated string
	bytes32 public immutable nativeCurrencyLabelBytes;

	constructor(address _WETH9, bytes32 _nativeCurrencyLabelBytes) {
		WETH9 = _WETH9;
		nativeCurrencyLabelBytes = _nativeCurrencyLabelBytes;
	}

	/// @notice Returns the native currency label as a string
	function nativeCurrencyLabel() public view returns (string memory) {
		uint256 len = 0;
		while (len < 32 && nativeCurrencyLabelBytes[len] != 0) {
			len++;
		}
		bytes memory b = new bytes(len);
		for (uint256 i = 0; i < len; i++) {
			b[i] = nativeCurrencyLabelBytes[i];
		}
		return string(b);
	}

	/// @inheritdoc INonfungibleTokenPositionDescriptor
	function tokenURI(
		INonfungiblePositionManager positionManager,
		uint256 tokenId
	) external view override returns (string memory) {
		(
			,
			,
			address token0,
			address token1,
			uint24 fee,
			int24 tickLower,
			int24 tickUpper,
			,
			,
			,
			,

		) = positionManager.positions(tokenId);

		IUniswapV3Pool pool = IUniswapV3Pool(
			PoolAddress.computeAddress(
				positionManager.factory(),
				PoolAddress.PoolKey({
					token0: token0,
					token1: token1,
					fee: fee
				})
			)
		);

		bool _flipRatio = flipRatio(token0, token1, ChainId.get());
		address quoteTokenAddress = !_flipRatio ? token1 : token0;
		address baseTokenAddress = !_flipRatio ? token0 : token1;
		(, int24 tick, , , , , ) = pool.slot0();

		return
			NFTDescriptor.constructTokenURI(
				NFTDescriptor.ConstructTokenURIParams({
					tokenId: tokenId,
					quoteTokenAddress: quoteTokenAddress,
					baseTokenAddress: baseTokenAddress,
					quoteTokenSymbol: quoteTokenAddress == WETH9
						? nativeCurrencyLabel()
						: SafeERC20Namer.tokenSymbol(quoteTokenAddress),
					baseTokenSymbol: baseTokenAddress == WETH9
						? nativeCurrencyLabel()
						: SafeERC20Namer.tokenSymbol(baseTokenAddress),
					quoteTokenDecimals: IERC20Metadata(quoteTokenAddress)
						.decimals(),
					baseTokenDecimals: IERC20Metadata(baseTokenAddress)
						.decimals(),
					flipRatio: _flipRatio,
					tickLower: tickLower,
					tickUpper: tickUpper,
					tickCurrent: tick,
					tickSpacing: pool.tickSpacing(),
					fee: fee,
					poolAddress: address(pool)
				})
			);
	}

	function flipRatio(
		address token0,
		address token1,
		uint256 chainId
	) public view returns (bool) {
		return
			tokenRatioPriority(token0, chainId) >
			tokenRatioPriority(token1, chainId);
	}

	function tokenRatioPriority(
		address token,
		uint256 chainId
	) public view returns (int256) {
		if (token == WETH9) {
			return TokenRatioSortOrder.DENOMINATOR;
		}
		if (chainId == 1) {
			if (token == USDC) {
				return TokenRatioSortOrder.NUMERATOR_MOST;
			} else if (token == USDT) {
				return TokenRatioSortOrder.NUMERATOR_MORE;
			} else if (token == DAI) {
				return TokenRatioSortOrder.NUMERATOR;
			} else if (token == TBTC) {
				return TokenRatioSortOrder.DENOMINATOR_MORE;
			} else if (token == WBTC) {
				return TokenRatioSortOrder.DENOMINATOR_MOST;
			} else {
				return 0;
			}
		}
		return 0;
	}
}
