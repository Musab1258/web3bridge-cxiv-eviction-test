// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Deposits {
    mapping(address => uint256) public balances;
    uint256 public totalVaultValue;

    bool internal _depositsPaused;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);

    receive() external payable virtual {
        require(!_depositsPaused, "Deposits: paused");
        balances[msg.sender] += msg.value;
        totalVaultValue      += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable virtual {
        require(!_depositsPaused, "Deposits: paused");
        balances[msg.sender] += msg.value;
        totalVaultValue      += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external virtual {
        require(!_depositsPaused,           "Deposits: paused");
        require(balances[msg.sender] >= amount, "Deposits: insufficient balance");

        balances[msg.sender] -= amount;
        totalVaultValue      -= amount;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Deposits: ETH transfer failed");

        emit Withdrawal(msg.sender, amount);
    }
}
