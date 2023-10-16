// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IVaultData {
    struct AllocationData {
        uint256 holdAllocation; // hodl
        uint256 uniswapAllocation; // Simmilar to T-Swap
        uint256 aaveAllocation; // Similar to Thunder Loan
    }
}
