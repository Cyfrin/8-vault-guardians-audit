// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPool} from "../../vendor/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AaveAdapter {
    using SafeERC20 for IERC20;

    error AaveAdapter__TransferFailed();

    IPool public immutable i_aavePool;

    constructor(address aavePool) {
        i_aavePool = IPool(aavePool);
    }

    /**
     * @notice Used by the vault to deposit vault's underlying asset token as lending amount in Aave v3
     * @param asset The vault's underlying asset token 
     * @param amount The amount of vault's underlying asset token to invest
     */
    function _aaveInvest(IERC20 asset, uint256 amount) internal {
        bool succ = asset.approve(address(i_aavePool), amount);
        if (!succ) {
            revert AaveAdapter__TransferFailed();
        }
        i_aavePool.supply({
            asset: address(asset),
            amount: amount,
            onBehalfOf: address(this), // decides who get's Aave's aTokens for the investment. In this case, mint it to the vault
            referralCode: 0
        });
    }

    /**
     * @notice Used by the vault to withdraw the its underlying asset token deposited as lending amount in Aave v3
     * @param token The vault's underlying asset token to withdraw
     * @param amount The amount of vault's underlying asset token to withdraw
     */
    function _aaveDivest(IERC20 token, uint256 amount) internal returns (uint256 amountOfAssetReturned) {
        i_aavePool.withdraw({
            asset: address(token),
            amount: amount,
            to: address(this)
        });
    }
}
