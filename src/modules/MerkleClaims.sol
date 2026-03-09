// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract MerkleClaims {
    bytes32 public merkleRoot;
    mapping(address => bool)   public claimed;
    mapping(bytes32 => bool)   public usedHashes;

    bool internal _claimsPaused;

    event MerkleRootSet(bytes32 indexed newRoot);
    event Claim(address indexed claimant, uint256 amount);

    function _setMerkleRoot(bytes32 root) internal {
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function claim(bytes32[] calldata proof, uint256 amount) external virtual {
        require(!_claimsPaused, "MerkleClaims: paused");

        bytes32 leaf     = keccak256(abi.encodePacked(msg.sender, amount));
        bytes32 computed = MerkleProof.processProof(proof, leaf);
        require(computed == merkleRoot, "MerkleClaims: invalid proof");
        require(!claimed[msg.sender],  "MerkleClaims: already claimed");

        claimed[msg.sender] = true;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "MerkleClaims: ETH transfer failed");

        emit Claim(msg.sender, amount);
    }

    function verifySignature(
        address signer,
        bytes32 messageHash,
        bytes memory signature
    ) external pure returns (bool) {
        return ECDSA.recover(messageHash, signature) == signer;
    }
}