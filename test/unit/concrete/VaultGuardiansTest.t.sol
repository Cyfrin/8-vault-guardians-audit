// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Base_Test} from "../../Base.t.sol";
import {VaultShares} from "../../../src/protocol/VaultShares.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";
import {VaultGuardians, IERC20} from "../../../src/protocol/VaultGuardians.sol";

contract VaultGuardiansTest is Base_Test {
    address user = makeAddr("user");

    uint256 mintAmount = 100 ether;

    function setUp() public override {
        Base_Test.setUp();
    }

    function testUpdateGuardianStakePrice() public {
        uint256 newStakePrice = 10;
        vm.prank(vaultGuardians.owner());
        vaultGuardians.updateGuardianStakePrice(newStakePrice);
        assertEq(vaultGuardians.getGuardianStakePrice(), newStakePrice);
    }

    function testUpdateGuardianStakePriceOnlyOwner() public {
        uint256 newStakePrice = 10;
        vm.prank(user);
        vm.expectRevert();
        vaultGuardians.updateGuardianStakePrice(newStakePrice);
    }

    function testUpdateGuardianAndDaoCut() public {
        uint256 newGuardianAndDaoCut = 10;
        vm.prank(vaultGuardians.owner());
        vaultGuardians.updateGuardianAndDaoCut(newGuardianAndDaoCut);
        assertEq(vaultGuardians.getGuardianAndDaoCut(), newGuardianAndDaoCut);
    }

    function testUpdateGuardianAndDaoCutOnlyOwner() public {
        uint256 newGuardianAndDaoCut = 10;
        vm.prank(user);
        vm.expectRevert();
        vaultGuardians.updateGuardianAndDaoCut(newGuardianAndDaoCut);
    }

    function testSweepErc20s() public {
        ERC20Mock mock = new ERC20Mock();
        mock.mint(mintAmount, msg.sender);
        vm.prank(msg.sender);
        mock.transfer(address(vaultGuardians), mintAmount);

        uint256 balanceBefore = mock.balanceOf(address(vaultGuardianGovernor));

        vm.prank(vaultGuardians.owner());
        vaultGuardians.sweepErc20s(IERC20(mock));

        uint256 balanceAfter = mock.balanceOf(address(vaultGuardianGovernor));

        assertEq(balanceAfter - balanceBefore, mintAmount);
    }
}
