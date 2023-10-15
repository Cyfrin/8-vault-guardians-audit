// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {InvestableUniverseAdapter} from "../../interfaces/InvestableUniverseAdapter.sol";

contract AaveAdapter is InvestableUniverseAdapter {
    function invest() external {}
    function divest() external {}
}
