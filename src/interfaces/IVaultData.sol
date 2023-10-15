// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IVaultShares} from "./IVaultShares.sol";

interface IVaultData {
    struct VaultData {
        IVaultShares vaultAddress;
        AllocationData allocations;
    }

    struct AllocationData {
        uint256 holdAllocation;
        uint256 tswapAllocation;
        uint256 thunderLoanAllocation;
    }
}
