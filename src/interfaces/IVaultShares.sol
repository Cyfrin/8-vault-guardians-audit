// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IVaultData} from "./IVaultData.sol";

interface IVaultShares is IERC4626, IVaultData {
    function updateHoldingAllocation(AllocationData memory tokenAllocationData) external;
}
