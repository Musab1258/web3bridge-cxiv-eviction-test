// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./base/MultiSig.sol";
import "./modules/Deposits.sol";
import "./modules/MerkleClaims.sol";
import "./modules/EmergencyControls.sol";
import "./interfaces/IEvictionVault.sol";

contract EvictionVault is
    MultiSig,
    Deposits,
    MerkleClaims,
    EmergencyControls,
    IEvictionVault
{
    // Constructor
    constructor(
        address[] memory _owners,
        uint256 _threshold
    ) payable MultiSig(_owners, _threshold) {
        if (msg.value > 0) {
            totalVaultValue += msg.value;
        }
    }

    receive() external payable override(Deposits) {
        require(!paused, "EvictionVault: paused");
        balances[msg.sender] += msg.value;
        totalVaultValue      += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Deposit / Withdraw (pause-aware)
    function deposit() external payable override(Deposits, IEvictionVault) whenNotPaused {
        balances[msg.sender] += msg.value;
        totalVaultValue      += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount)
        external
        override(Deposits, IEvictionVault)
        whenNotPaused
    {
        require(balances[msg.sender] >= amount, "EvictionVault: insufficient balance");
        balances[msg.sender] -= amount;
        totalVaultValue      -= amount;
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "EvictionVault: ETH transfer failed");
        emit Withdrawal(msg.sender, amount);
    }

    // MultiSig overrides (IEvictionVault signatures)
    function submitTransaction(address to, uint256 value, bytes calldata data)
        external
        override(MultiSig, IEvictionVault)
        returns (uint256)
    {
        require(!paused, "EvictionVault: paused");
        return MultiSig.submitTransaction(to, value, data);
    }

    function confirmTransaction(uint256 txId)
        external
        override(MultiSig, IEvictionVault)
    {
        require(!paused, "EvictionVault: paused");
        MultiSig.confirmTransaction(txId);
    }

    function executeTransaction(uint256 txId)
        external
        override(MultiSig, IEvictionVault)
    {
        MultiSig.executeTransaction(txId);
    }

    // Merkle Claims
    function setMerkleRoot(bytes32 root)
        external
        override(IEvictionVault)
        onlyOwner
    {
        _setMerkleRoot(root);
    }

    function claim(bytes32[] calldata proof, uint256 amount)
        external
        override(MerkleClaims, IEvictionVault)
        whenNotPaused
    {
        MerkleClaims.claim(proof, amount);
    }

    // Emergency Controls
    function pause()
        external
        override(IEvictionVault)
        onlyOwner
    {
        _pause();
    }

    function unpause()
        external
        override(IEvictionVault)
        onlyOwner
    {
        _unpause();
    }

    // Helpers
    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
