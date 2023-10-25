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

    function _aaveInvest(IERC20 asset, uint256 amount) internal {
        bool succ = asset.approve(address(i_aavePool), amount);
        if (!succ) {
            revert AaveAdapter__TransferFailed();
        }
        i_aavePool.supply({
            asset: address(asset),
            amount: amount,
            onBehalfOf: address(this),
            referralCode: 0
        });
    }

    function _aaveDivest(IERC20 token, uint256 amount) internal returns (uint256 amountOfAssetReturned) {
        i_aavePool.withdraw({
            asset: address(token),
            amount: amount,
            to: address(this)
        });
    }
}
