// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Counter {
    AggregatorV3Interface internal dataFeed;

    constructor() {
        interval = 120;
        lastTimeStamp = block.timestamp;

        counter = 0;

        /**
         * Network: BaseSepolia
         * Aggregator: BTC/USD
         * Address: 0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298
         */
        dataFeed = AggregatorV3Interface(
            0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298
        );
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }
}
