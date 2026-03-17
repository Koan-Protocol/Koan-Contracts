// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleDebugger
 * @notice A simple contract to debug oracle logic from KoanprotocolPrediction
 * @dev Deploy this contract and call the debug functions to see oracle data
 */
contract OracleDebugger {
    AggregatorV3Interface public oracle;
    uint256 public oracleLatestRoundId;
    uint256 public oracleUpdateAllowance;

    event OracleDebugInfo(
        uint80 roundId,
        int256 price,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound,
        uint256 blockTimestamp,
        uint256 oracleUpdateAllowance,
        uint256 storedOracleLatestRoundId
    );

    event PriceCheckResult(
        bool success,
        string message,
        uint80 roundId,
        int256 price
    );

    constructor(address _oracleAddress, uint256 _oracleUpdateAllowance) {
        oracle = AggregatorV3Interface(_oracleAddress);
        oracleUpdateAllowance = _oracleUpdateAllowance;
        oracleLatestRoundId = 0;
    }

    /**
     * @notice Get raw oracle data without any checks
     */
    function getRawOracleData()
        external
        view
        returns (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return oracle.latestRoundData();
    }

    /**
     * @notice Debug function that returns all relevant data for debugging
     */
    function debugOracleState()
        external
        view
        returns (
            uint80 roundId,
            int256 price,
            uint256 oracleTimestamp,
            uint256 currentBlockTimestamp,
            uint256 configuredAllowance,
            uint256 storedLatestRoundId,
            uint256 leastAllowedTimestamp_BUGGY,
            uint256 leastAllowedTimestamp_CORRECT,
            bool timestampCheck_BUGGY,
            bool timestampCheck_CORRECT,
            bool roundIdCheck
        )
    {
        (uint80 _roundId, int256 _price, , uint256 _timestamp, ) = oracle
            .latestRoundData();

        // BUGGY logic from original contract: block.timestamp + oracleUpdateAllowance
        uint256 _leastAllowedBuggy = block.timestamp + oracleUpdateAllowance;

        // CORRECT logic should be: block.timestamp - oracleUpdateAllowance
        uint256 _leastAllowedCorrect = block.timestamp - oracleUpdateAllowance;

        return (
            _roundId,
            _price,
            _timestamp,
            block.timestamp,
            oracleUpdateAllowance,
            oracleLatestRoundId,
            _leastAllowedBuggy,
            _leastAllowedCorrect,
            _timestamp <= _leastAllowedBuggy, // This is the BUGGY check (always true unless future timestamp)
            _timestamp >= _leastAllowedCorrect, // This is the CORRECT check for staleness
            uint256(_roundId) > oracleLatestRoundId
        );
    }

    /**
     * @notice Simulate _getPriceFromOracle with detailed error messages
     * @dev This mimics the exact logic from KoanprotocolPrediction._getPriceFromOracle()
     */
    function simulateGetPriceFromOracle()
        external
        view
        returns (
            bool success,
            string memory message,
            uint80 roundId,
            int256 price
        )
    {
        (uint80 _roundId, int256 _price, , uint256 _timestamp, ) = oracle
            .latestRoundData();

        // ORIGINAL BUGGY LOGIC FROM CONTRACT:
        // uint256 leastAllowedTimestamp = block.timestamp + oracleUpdateAllowance;
        // require(timestamp <= leastAllowedTimestamp, "Oracle update exceeded max timestamp allowance");

        uint256 leastAllowedTimestamp = block.timestamp + oracleUpdateAllowance;

        // Check 1: Timestamp check (BUGGY - this checks if oracle timestamp is not in the future beyond allowance)
        if (_timestamp > leastAllowedTimestamp) {
            return (
                false,
                "Oracle update exceeded max timestamp allowance",
                _roundId,
                _price
            );
        }

        // Check 2: Round ID check
        if (uint256(_roundId) <= oracleLatestRoundId) {
            return (
                false,
                string(
                    abi.encodePacked(
                        "Oracle update roundId must be larger than oracleLatestRoundId. Current roundId: ",
                        _uint2str(uint256(_roundId)),
                        ", stored oracleLatestRoundId: ",
                        _uint2str(oracleLatestRoundId)
                    )
                ),
                _roundId,
                _price
            );
        }

        return (true, "Oracle check passed", _roundId, _price);
    }

    /**
     * @notice Check all potential failure points with detailed analysis
     */
    function analyzeOracleIssues()
        external
        view
        returns (
            string memory analysis,
            bool isRoundIdIssue,
            bool isTimestampIssue,
            bool isPriceZeroIssue,
            uint256 roundIdDifference,
            uint256 timestampAge
        )
    {
        (uint80 _roundId, int256 _price, , uint256 _timestamp, ) = oracle
            .latestRoundData();

        bool _isRoundIdIssue = uint256(_roundId) <= oracleLatestRoundId;
        bool _isTimestampIssue = false; // The buggy check almost never fails
        bool _isPriceZeroIssue = _price == 0;

        uint256 _roundIdDiff = 0;
        if (_isRoundIdIssue) {
            _roundIdDiff = oracleLatestRoundId - uint256(_roundId);
        } else {
            _roundIdDiff = uint256(_roundId) - oracleLatestRoundId;
        }

        uint256 _timestampAge = 0;
        if (block.timestamp > _timestamp) {
            _timestampAge = block.timestamp - _timestamp;
        }

        string memory _analysis;
        if (_isRoundIdIssue) {
            _analysis = "ISSUE: Oracle roundId is not larger than stored oracleLatestRoundId. This happens when executeRound() is called but the oracle hasn't updated with a new round yet.";
        } else if (_isPriceZeroIssue) {
            _analysis = "ISSUE: Oracle is returning price = 0. Check oracle configuration.";
        } else if (_timestampAge > 3600) {
            _analysis = "WARNING: Oracle price is stale (more than 1 hour old). The buggy timestamp check won't catch this.";
        } else {
            _analysis = "Oracle appears to be working correctly. Issue may be elsewhere.";
        }

        return (
            _analysis,
            _isRoundIdIssue,
            _isTimestampIssue,
            _isPriceZeroIssue,
            _roundIdDiff,
            _timestampAge
        );
    }

    /**
     * @notice Simulate what would happen if we update oracleLatestRoundId
     */
    function simulateAfterRoundIdUpdate(
        uint256 newOracleLatestRoundId
    ) external view returns (bool wouldPass, string memory reason) {
        (uint80 _roundId, , , , ) = oracle.latestRoundData();

        if (uint256(_roundId) <= newOracleLatestRoundId) {
            return (
                false,
                "Would fail: Oracle roundId would not be larger than new oracleLatestRoundId"
            );
        }
        return (
            true,
            "Would pass: Oracle roundId is larger than new oracleLatestRoundId"
        );
    }

    /**
     * @notice Set oracleLatestRoundId for testing
     */
    function setOracleLatestRoundId(uint256 _newRoundId) external {
        oracleLatestRoundId = _newRoundId;
    }

    /**
     * @notice Set oracleUpdateAllowance for testing
     */
    function setOracleUpdateAllowance(uint256 _newAllowance) external {
        oracleUpdateAllowance = _newAllowance;
    }

    /**
     * @notice Set oracle address for testing
     */
    function setOracle(address _newOracle) external {
        oracle = AggregatorV3Interface(_newOracle);
    }

    /**
     * @notice Get oracle decimals
     */
    function getOracleDecimals() external view returns (uint8) {
        return oracle.decimals();
    }

    /**
     * @notice Get oracle description
     */
    function getOracleDescription() external view returns (string memory) {
        return oracle.description();
    }

    /**
     * @notice Helper to convert uint to string
     */
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
