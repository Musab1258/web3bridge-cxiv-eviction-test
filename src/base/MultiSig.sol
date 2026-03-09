// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Timelock.sol";

abstract contract MultiSig is Timelock {

    struct Transaction {
        address to;
        uint256 value;
        bytes   data;
        bool    executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public threshold;

    mapping(uint256 => Transaction)              public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;
    uint256 public txCount;

    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "MultiSig: not owner");
        _;
    }

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "MultiSig: no owners");
        require(
            _threshold > 0 && _threshold <= _owners.length,
            "MultiSig: invalid threshold"
        );
        threshold = _threshold;

        for (uint256 i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0), "MultiSig: zero address owner");
            require(!isOwner[o],     "MultiSig: duplicate owner");
            isOwner[o] = true;
            owners.push(o);
        }
    }

    function submitTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) public virtual returns (uint256 txId) {
        require(isOwner[msg.sender], "MultiSig: not owner");
        txId = txCount++;
        transactions[txId] = Transaction({
            to:             to,
            value:          value,
            data:           data,
            executed:       false,
            confirmations:  1,
            submissionTime: block.timestamp,
            executionTime:  0
        });
        confirmed[txId][msg.sender] = true;

        if (threshold == 1) {
            transactions[txId].executionTime = _scheduledTime();
        }

        emit Submission(txId);
    }

    function confirmTransaction(uint256 txId) public virtual {
        require(isOwner[msg.sender], "MultiSig: not owner");
        Transaction storage txn = transactions[txId];
        require(!txn.executed,                "MultiSig: already executed");
        require(!confirmed[txId][msg.sender], "MultiSig: already confirmed");

        confirmed[txId][msg.sender] = true;
        txn.confirmations++;

        if (txn.confirmations == threshold) {
            txn.executionTime = _scheduledTime();
        }

        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) public virtual {
        Transaction storage txn = transactions[txId];
        require(txn.confirmations >= threshold,    "MultiSig: below threshold");
        require(!txn.executed,                     "MultiSig: already executed");
        require(_timelockReady(txn.executionTime), "MultiSig: timelock not elapsed");

        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "MultiSig: execution failed");

        emit Execution(txId);
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }
}