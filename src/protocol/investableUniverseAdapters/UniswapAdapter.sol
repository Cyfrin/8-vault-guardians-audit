// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ISwapRouter} from "@uniswap/contracts/interfaces/ISwapRouter.sol";
import {IInvestableUniverseAdapter} from "../../interfaces/InvestableUniverseAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapAdapter is IInvestableUniverseAdapter {
    function invest(IERC20 token, uint256 amount) external {}
    function divest(IERC20 token, uint256 amount) external {}
}
