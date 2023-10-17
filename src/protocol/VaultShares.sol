// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC4626, ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IVaultShares, IERC4626} from "../interfaces/IVaultShares.sol";
import {AaveAdapter, IPool} from "./investableUniverseAdapters/AaveAdapter.sol";
import {UniswapAdapter} from "./investableUniverseAdapters/UniswapAdapter.sol";
import {DataTypes} from "../vendor/DataTypes.sol";

contract VaultShares is ERC4626, IVaultShares, AaveAdapter, UniswapAdapter {
    error VaultShares__DepositMoreThanMax(uint256 amount, uint256 max);
    error VaultShares__NotGuardian();
    error VaultShares__AllocationNot100Percent(uint256 totalAllocation);

    address private immutable i_guardian;
    IERC20 internal immutable i_uniswapLiquidityToken;
    IERC20 internal immutable i_aaveAToken;

    AllocationData private s_allocationData;

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
        AllocationData memory allocationData,
        address aavePool,
        address uniswapRouter
    ) ERC4626(asset) ERC20(vaultName, vaultSymbol) AaveAdapter(aavePool) UniswapAdapter(uniswapRouter) {
        i_guardian = guardian;
        _updateHoldingAllocation(allocationData);

        // External calls
        i_aaveAToken = IERC20(IPool(aavePool).getReserveData(address(asset)).aTokenAddress);
        i_uniswapLiquidityToken = IERC20(i_uniswapFactory.getPair(address(asset), address(WETH)));
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

        uniswapInvest(IERC20(asset()), uniswapAllocation);
        aaveInvest(IERC20(asset()), aaveAllocation);
    }

    /* 
     * @notice Unintelligently just withdraws everything, and then reinvests it all. 
     * @notice Anyone can call this and pay the gas costs to rebalance the portfolio at any time. 
     * @dev We understand that this is horrible for gas costs. 
     */
    function rebalanceFunds() public {
        uint256 uniswapLiquidityTokensBalance = i_uniswapLiquidityToken.balanceOf(address(this));
        uint256 aaveAtokensBalance = i_aaveAToken.balanceOf(address(this));

        // Divest
        uint256 assetsFromUniswap = uniswapDivest(IERC20(asset()), uniswapLiquidityTokensBalance);
        uint256 assetsFromAave = aaveDivest(IERC20(asset()), aaveAtokensBalance);

        // Reinvest
        _investFunds(assetsFromUniswap + assetsFromAave);
    }
}
