// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("Mock ERC20", "ME") {}

    function mint(uint256 amount, address to) external {
        _mint(to, amount);
    }

    function burn(uint256 amount, address from) external {
        _burn(from, amount);
    }

    // add this to be excluded from coverage report
    function test() public {}
}
