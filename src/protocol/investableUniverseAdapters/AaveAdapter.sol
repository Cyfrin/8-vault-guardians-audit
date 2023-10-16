// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {IInvestableUniverseAdapter} from "../../interfaces/InvestableUniverseAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveAdapter is IInvestableUniverseAdapter {
    function invest(IERC20 token, uint256 amount) external {}
    function divest(IERC20 token, uint256 amount) external {}
}
