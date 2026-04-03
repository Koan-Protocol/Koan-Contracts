// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract PeriodicAccuracyTest is Test {
    Counter counter;

    function setUp() public {
        counter = new Counter(300);
    }

    function test_FirstCheckpoint_RecordsOffset() public {
        // Warp so first call is ~5s early
        vm.warp(block.timestamp + 295);
        counter.checkpoint();
        (
            uint256 count,
            uint256 expected,
            uint256 actual,
            int256 offset,
            address caller
        ) = counter.records(1);
        assertEq(count, 1);
        assertEq(expected, block.timestamp - 295 + 300); // lastTimestamp set at deploy time
        assertEq(actual, block.timestamp);
        // offset should be close to -5
        assertEq(offset, int256(actual) - int256(expected));
        assertEq(caller, address(this));
    }

    function test_LateCheckpoint_PositiveOffset() public {
        // First call at +310s => offset = +10
        vm.warp(block.timestamp + 310);
        counter.checkpoint();
        (, uint256 expected, uint256 actual, int256 offset, ) = counter.records(
            1
        );
        assertEq(int256(actual) - int256(expected), offset);
        assertGt(offset, 0);
        assertEq(uint256(offset), 10);

        // Second call exactly 300s later => offset ~ 0
        vm.warp(block.timestamp + 300);
        counter.checkpoint();
        (, expected, actual, offset, ) = counter.records(2);
        assertEq(int256(actual) - int256(expected), offset);
        assertEq(offset, 0);
    }

    function test_MultipleCheckpoints_TrackersAdvance() public {
        // Three checkpoints 300s apart
        vm.warp(block.timestamp + 300);
        counter.checkpoint();
        vm.warp(block.timestamp + 300);
        counter.checkpoint();
        vm.warp(block.timestamp + 300);
        counter.checkpoint();

        (uint256 count, , , , ) = counter.records(3);
        assertEq(count, 3);

        // latestRecord should match last
        Counter.AccuracyRecord memory rec = counter.latestRecord();
        assertEq(rec.count, 3);
    }
}
