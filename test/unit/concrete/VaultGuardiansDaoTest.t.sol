// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Base_Test} from "../../Base.t.sol";
import {VaultShares} from "../../../src/protocol/VaultShares.sol";
import {IERC20} from "../../../src/protocol/VaultGuardians.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";
import {VaultGuardiansBase} from "../../../src/protocol/VaultGuardiansBase.sol";

contract VaultGuardiansDaoTest is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
    }

    function testDaoSetupIsCorrect() public {
        assertEq(vaultGuardianToken.balanceOf(msg.sender), 0);
        assertEq(vaultGuardianToken.owner(), address(vaultGuardians));
    }
}
