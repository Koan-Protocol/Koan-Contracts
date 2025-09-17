// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceFeed {
    /// @notice Get latest price from Chainlink feed
    function getLatestPrice(address feed) internal view returns (int256) {
        (
            ,
            // uint80 roundId
            int256 answer, // uint256 startedAt // uint256 updatedAt
            ,
            ,

        ) = // uint80 answeredInRound
            AggregatorV3Interface(feed).latestRoundData();
        return answer;
    }

    /// @notice Convert USD amount (with 8 decimals) to ETH amount
    function getEthAmountFromUsd(
        address feed,
        uint256 usdAmount // e.g. 50_000_000 for $0.5
    ) internal view returns (uint256) {
        int256 price = getLatestPrice(feed);
        require(price > 0, "Invalid price from oracle");

        return (usdAmount * 1 ether) / uint256(price);
    }
}
