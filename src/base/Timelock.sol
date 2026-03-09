// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Timelock {
    uint256 public constant TIMELOCK_DURATION = 1 hours;

    function _timelockReady(uint256 executionTime) internal view returns (bool) {
        return executionTime != 0 && block.timestamp >= executionTime;
    }

    function _scheduledTime() internal view returns (uint256) {
        return block.timestamp + TIMELOCK_DURATION;
    }
}
