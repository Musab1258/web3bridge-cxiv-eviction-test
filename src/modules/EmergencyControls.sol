// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract EmergencyControls {
    bool public paused;

    event Paused(address indexed caller);
    event Unpaused(address indexed caller);

    modifier whenNotPaused() {
        require(!paused, "EmergencyControls: paused");
        _;
    }

    function _pause() internal {
        require(!paused, "EmergencyControls: already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal {
        require(paused, "EmergencyControls: not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }
}
