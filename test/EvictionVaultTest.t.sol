// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EvictionVault.sol";

contract EvictionVaultTest is Test {
    EvictionVault internal vault;

    address internal owner1 = address(0x1);
    address internal owner2 = address(0x2);
    address internal owner3 = address(0x3);
    address internal alice   = address(0xA11CE);
    address internal attacker = address(0xBAD);

    address[] internal owners;

    // Setup

    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);

        vault = new EvictionVault{value: 10 ether}(owners, 2);

        // Fund test accounts
        vm.deal(alice,   10 ether);
        vm.deal(attacker, 1 ether);
        vm.deal(owner1,   5 ether);
    }

    // TEST 1 – Deposit & Withdraw

    function test_DepositAndWithdraw() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();

        assertEq(vault.balances(alice), 1 ether, "balance after deposit");
        assertEq(vault.totalVaultValue(), 11 ether, "vault value after deposit");

        uint256 aliceBefore = alice.balance;

        vm.prank(alice);
        vault.withdraw(0.5 ether);

        assertEq(vault.balances(alice), 0.5 ether, "balance after withdraw");
        assertEq(alice.balance, aliceBefore + 0.5 ether, "alice ETH after withdraw");
    }

    // TEST 2 – receive()

    function test_Receive_CreditsMsgSender() public {
        vm.prank(alice);
        (bool ok,) = address(vault).call{value: 1 ether}("");
        assertTrue(ok, "receive failed");

        assertEq(vault.balances(alice), 1 ether, "receive should credit msg.sender");
    }

    // TEST 3 – MultiSig: submit → confirm → timelock → execute

    function test_MultiSig_FullFlow() public {
        vm.prank(owner1);
        uint256 txId = vault.submitTransaction(alice, 1 ether, "");

        (, , , , , , uint256 execTime1) = vault.transactions(txId);
        assertEq(execTime1, 0, "executionTime should be 0 before threshold");

        vm.prank(owner2);
        vault.confirmTransaction(txId);

        (, , , , , , uint256 execTime2) = vault.transactions(txId);
        assertGt(execTime2, 0, "executionTime should be set after threshold");

        vm.expectRevert("MultiSig: timelock not elapsed");
        vault.executeTransaction(txId);

        vm.warp(block.timestamp + 1 hours + 1);

        uint256 aliceBefore = alice.balance;
        vault.executeTransaction(txId);
        assertEq(alice.balance, aliceBefore + 1 ether, "alice should receive 1 ETH");

        (, , , bool executed, , , ) = vault.transactions(txId);
        assertTrue(executed, "tx should be marked executed");
    }

    // TEST 4 – Merkle Claim

    function test_MerkleClaim() public {
        uint256 claimAmount = 0.5 ether;
        bytes32 leaf = keccak256(abi.encodePacked(alice, claimAmount));

        vm.expectRevert("MultiSig: not owner");
        vm.prank(attacker);
        vault.setMerkleRoot(leaf);

        vm.prank(owner1);
        vault.setMerkleRoot(leaf);
        assertEq(vault.merkleRoot(), leaf);

        uint256 aliceBefore = alice.balance;
        bytes32[] memory proof = new bytes32[](0);

        vm.prank(alice);
        vault.claim(proof, claimAmount);

        assertEq(alice.balance, aliceBefore + claimAmount, "alice should receive claim");
        assertTrue(vault.claimed(alice), "alice should be marked as claimed");

        vm.expectRevert("MerkleClaims: already claimed");
        vm.prank(alice);
        vault.claim(proof, claimAmount);
    }
}
