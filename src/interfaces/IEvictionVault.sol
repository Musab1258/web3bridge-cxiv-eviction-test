// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEvictionVault {
    // Deposits / Withdrawals
    function deposit() external payable;
    function withdraw(uint256 amount) external;

    // Merkle Claims
    function setMerkleRoot(bytes32 root) external;
    function claim(bytes32[] calldata proof, uint256 amount) external;

    // Admin
    function pause() external;
    function unpause() external;
}