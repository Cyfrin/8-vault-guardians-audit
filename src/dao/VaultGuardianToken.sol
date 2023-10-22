// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit, Nonces} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract VaultGuardianToken is ERC20, ERC20Permit, ERC20Votes {
    uint256 private constant INITIAL_TOTAL_SUPPLY = 10_000_000e18;

    constructor() ERC20("VaultGuardianToken", "VGT") ERC20Permit("VaultGuardianToken") {
        _mint(msg.sender, INITIAL_TOTAL_SUPPLY);
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function getInitialTotalSupply() external pure returns (uint256) {
        return INITIAL_TOTAL_SUPPLY;
    }
}
