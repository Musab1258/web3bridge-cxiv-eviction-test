# Eviction Vault — Hardening Challenge

## Overview

This repository refactors the monolithic `EvictionVault` smart contract into a
secure, modular Foundry project and mitigates all six critical vulnerabilities
identified in the challenge brief.

---

## Critical Vulnerability Fixes Test

1. `setMerkleRoot` — Callable by Anyone → `onlyOwner`

2. `emergencyWithdrawAll` — Public Drain → **Removed**


3. `pause` / `unpause` — Single Owner → `onlyOwner` (multisig-submittable)

4. `receive()` — `tx.origin` → `msg.sender`

## Running the Tests

```bash
# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts

# Build
forge build

# Test 
forge test -vvv
```