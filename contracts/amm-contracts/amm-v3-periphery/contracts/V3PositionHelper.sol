// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import { PositionValue } from "./libraries/PositionValue.sol";
import { INonfungiblePositionManager } from "./interfaces/INonfungiblePositionManager.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";

/// @dev Mirrors the on-chain tuple from INonfungiblePositionManager.positions(), plus tokenId.
struct Position {
	uint256 tokenId;
	uint96 nonce;
	address operator;
	address token0;
	address token1;
	uint24 fee;
	int24 tickLower;
	int24 tickUpper;
	uint128 liquidity;
	uint256 feeGrowthInside0LastX128;
	uint256 feeGrowthInside1LastX128;
	uint128 tokensOwed0;
	uint128 tokensOwed1;
}

/// @title V3PositionHelper
/// @notice Helper contract to fetch Uniswap V3 positions with live fee accruals.
contract V3PositionHelper {
	/// @notice Returns a single position with up-to-date fees owed
	/// @param positionManager The NonfungiblePositionManager address
	/// @param tokenId         The tokenId of the position
	/// @return position       The full Position struct with tokensOwed0/1 patched
	function getPosition(
		INonfungiblePositionManager positionManager,
		uint256 tokenId
	) public view returns (Position memory position) {
		{
			(
				uint96 nonce,
				address operator,
				address token0,
				address token1,
				uint24 fee,
				int24 tickLower,
				int24 tickUpper,
				uint128 liquidity,
				uint256 feeGrowthInside0LastX128,
				uint256 feeGrowthInside1LastX128,
				uint128 tokensOwed0,
				uint128 tokensOwed1
			) = positionManager.positions(tokenId);

			position = Position({
				tokenId: tokenId,
				nonce: nonce,
				operator: operator,
				token0: token0,
				token1: token1,
				fee: fee,
				tickLower: tickLower,
				tickUpper: tickUpper,
				liquidity: liquidity,
				feeGrowthInside0LastX128: feeGrowthInside0LastX128,
				feeGrowthInside1LastX128: feeGrowthInside1LastX128,
				tokensOwed0: tokensOwed0,
				tokensOwed1: tokensOwed1
			});
		}

		{
			(uint256 amount0, uint256 amount1) = PositionValue.fees(
				positionManager,
				tokenId
			);

			position.tokensOwed0 = SafeCast.toUint128(amount0);
			position.tokensOwed1 = SafeCast.toUint128(amount1);
		}
	}

	/// @notice Returns multiple positions with live fee updates
	/// @param positionManager The NonfungiblePositionManager address
	/// @param tokenIds        Array of position tokenIds
	/// @return positions      Array of full Position structs with updated fees
	function getPositions(
		INonfungiblePositionManager positionManager,
		uint256[] calldata tokenIds
	) external view returns (Position[] memory positions) {
		uint256 count = tokenIds.length;
		positions = new Position[](count);

		for (uint256 i = 0; i < count; i++) {
			positions[i] = getPosition(positionManager, tokenIds[i]);
		}
	}

	/// @notice Returns paginated positions owned by `user`, with live fee updates
	/// @param positionManager  The NonfungiblePositionManager
	/// @param user             Owner address whose positions to query
	/// @param skip             Number of positions to skip from the start of the list
	/// @param first            Maximum number of positions to return
	/// @return positions       Array of Position structs (at most `first` long)
	function getUserPositions(
		INonfungiblePositionManager positionManager,
		address user,
		uint256 skip,
		uint256 first
	) external view returns (Position[] memory positions) {
		uint256 balance = positionManager.balanceOf(user);
		if (skip >= balance) {
			return new Position[](0);
		}

		uint256 remaining = balance - skip;
		uint256 count = remaining < first ? remaining : first;
		positions = new Position[](count);

		for (uint256 i = 0; i < count; i++) {
			uint256 tokenId = positionManager.tokenOfOwnerByIndex(
				user,
				skip + i
			);
			positions[i] = getPosition(positionManager, tokenId);
		}
	}
}
