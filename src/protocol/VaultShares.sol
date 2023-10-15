// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC4626, ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IVaultData} from "../interfaces/IVaultData.sol";

contract VaultShares is ERC4626, IVaultData {
    error VaultShares__DepositMoreThanMax(uint256 amount, uint256 max);
    error VaultShares__NotGuardian();

    address public immutable i_guardian;
    AllocationData public s_allocationData;

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
        s_allocationData = allocationData;
    }

    /**
     * @dev See {IERC4626-deposit}. Overrides the Openzeppelin implementation.
     */
    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        if (assets > maxDeposit(receiver)) {
            revert VaultShares__DepositMoreThanMax(assets, maxDeposit(receiver));
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        _investFunds();
        return shares;
    }

    function _investFunds() private {}
}
