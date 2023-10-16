// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC4626, ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IVaultShares, IERC4626} from "../interfaces/IVaultShares.sol";

contract VaultShares is ERC4626, IVaultShares {
    error VaultShares__DepositMoreThanMax(uint256 amount, uint256 max);
    error VaultShares__NotGuardian();
    error VaultShares__AllocationNot100Percent(uint256 totalAllocation);

    address public immutable i_guardian;
    AllocationData public s_allocationData;

    uint256 private constant ALLOCATION_PRECISION = 1_000_000;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event UpdatedAllocation(AllocationData allocationData);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyGuardian() {
        if (msg.sender != i_guardian) {
            revert VaultShares__NotGuardian();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(
        IERC20 asset,
        string memory vaultName,
        string memory vaultSymbol,
        address guardian,
        AllocationData memory allocationData
    ) ERC4626(asset) ERC20(vaultName, vaultSymbol) {
        i_guardian = guardian;
        _updateHoldingAllocation(allocationData);
    }

    function _updateHoldingAllocation(AllocationData memory allocationData) private {
        uint256 totalAllocation =
            allocationData.holdAllocation + allocationData.uniswapAllocation + allocationData.aaveAllocation;
        if (totalAllocation != ALLOCATION_PRECISION) {
            revert VaultShares__AllocationNot100Percent(totalAllocation);
        }
        s_allocationData = allocationData;
        emit UpdatedAllocation(allocationData);
    }

    function updateHoldingAllocation(AllocationData memory tokenAllocationData) public onlyGuardian {
        _updateHoldingAllocation(tokenAllocationData);
    }

    /**
     * @dev See {IERC4626-deposit}. Overrides the Openzeppelin implementation.
     */
    function deposit(uint256 assets, address receiver) public override(ERC4626, IERC4626) returns (uint256) {
        if (assets > maxDeposit(receiver)) {
            revert VaultShares__DepositMoreThanMax(assets, maxDeposit(receiver));
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        _investFunds(assets);
        return shares;
    }

    function _investFunds(uint256 assets) private {
        uint256 uniswapAllocation = (assets * s_allocationData.uniswapAllocation) / ALLOCATION_PRECISION;
        uint256 aaveAllocation = (assets * s_allocationData.aaveAllocation) / ALLOCATION_PRECISION;
    }

    function rebalanceFunds() public {}
}
