// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Base_Test} from "../../Base.t.sol";
import {VaultShares} from "../../../src/protocol/VaultShares.sol";
import {IERC20} from "../../../src/protocol/VaultGuardians.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";
import {VaultGuardiansBase} from "../../../src/protocol/VaultGuardiansBase.sol";

import {VaultGuardians} from "../../../src/protocol/VaultGuardians.sol";
import {VaultGuardianGovernor} from "../../../src/dao/VaultGuardianGovernor.sol";
import {VaultGuardianToken} from "../../../src/dao/VaultGuardianToken.sol";
import {console} from "forge-std/console.sol";

contract VaultGuardiansBaseTest is Base_Test {
    address public guardian = makeAddr("guardian");
    address public user = makeAddr("user");

    VaultShares public wethVaultShares;
    VaultShares public usdcVaultShares;
    VaultShares public linkVaultShares;

    uint256 guardianAndDaoCut;
    uint256 stakePrice;
    uint256 mintAmount = 100 ether;

    // 500 hold, 250 uniswap, 250 aave
    AllocationData allocationData = AllocationData(500, 250, 250);
    AllocationData newAllocationData = AllocationData(0, 500, 500);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event GuardianAdded(address guardianAddress, IERC20 token);
    event GaurdianRemoved(address guardianAddress, IERC20 token);
    event InvestedInGuardian(address guardianAddress, IERC20 token, uint256 amount);
    event DinvestedFromGuardian(address guardianAddress, IERC20 token, uint256 amount);
    event GuardianUpdatedHoldingAllocation(address guardianAddress, IERC20 token);

    function setUp() public override {
        Base_Test.setUp();
        guardianAndDaoCut = vaultGuardians.getGuardianAndDaoCut();
        stakePrice = vaultGuardians.getGuardianStakePrice();
    }

    function testDefaultsToNonFork() public view {
        assert(block.chainid != 1);
    }

    function testSetupAddsTokensAndPools() public {
        assertEq(vaultGuardians.isApprovedToken(usdcAddress), true);
        assertEq(vaultGuardians.isApprovedToken(linkAddress), true);
        assertEq(vaultGuardians.isApprovedToken(wethAddress), true);

        assertEq(address(vaultGuardians.getWeth()), wethAddress);
        assertEq(address(vaultGuardians.getTokenOne()), usdcAddress);
        assertEq(address(vaultGuardians.getTokenTwo()), linkAddress);

        assertEq(vaultGuardians.getAavePool(), aavePool);
        assertEq(vaultGuardians.getUniswapV2Router(), uniswapRouter);
    }

    function testBecomeGuardian() public {
        weth.mint(mintAmount, guardian);
        vm.startPrank(guardian);
        weth.approve(address(vaultGuardians), mintAmount);
        address wethVault = vaultGuardians.becomeGuardian(allocationData);
        vm.stopPrank();

        assertEq(address(vaultGuardians.getVaultFromGuardianAndToken(guardian, weth)), wethVault);
    }

    function testBecomeGuardianMovesStakePrice() public {
        weth.mint(mintAmount, guardian);

        vm.startPrank(guardian);
        uint256 wethBalanceBefore = weth.balanceOf(address(guardian));
        weth.approve(address(vaultGuardians), mintAmount);
        vaultGuardians.becomeGuardian(allocationData);
        vm.stopPrank();

        uint256 wethBalanceAfter = weth.balanceOf(address(guardian));
        assertEq(wethBalanceBefore - wethBalanceAfter, vaultGuardians.getGuardianStakePrice());
    }

    function testBecomeGuardianEmitsEvent() public {
        weth.mint(mintAmount, guardian);

        vm.startPrank(guardian);
        weth.approve(address(vaultGuardians), mintAmount);
        vm.expectEmit(false, false, false, true, address(vaultGuardians));
        emit GuardianAdded(guardian, weth);
        vaultGuardians.becomeGuardian(allocationData);
        vm.stopPrank();
    }

    function testCantBecomeTokenGuardianWithoutBeingAWethGuardian() public {
        usdc.mint(mintAmount, guardian);
        vm.startPrank(guardian);
        usdc.approve(address(vaultGuardians), mintAmount);
        vm.expectRevert(
            abi.encodeWithSelector(
                VaultGuardiansBase.VaultGuardiansBase__NotAGuardian.selector, guardian, address(weth)
            )
        );
        vaultGuardians.becomeTokenGuardian(allocationData, usdc);
        vm.stopPrank();
    }

    modifier hasGuardian() {
        weth.mint(mintAmount, guardian);
        vm.startPrank(guardian);
        weth.approve(address(vaultGuardians), mintAmount);
        address wethVault = vaultGuardians.becomeGuardian(allocationData);
        wethVaultShares = VaultShares(wethVault);
        vm.stopPrank();
        _;
    }

    function testUpdatedHoldingAllocationEmitsEvent() public hasGuardian {
        vm.startPrank(guardian);
        vm.expectEmit(false, false, false, true, address(vaultGuardians));
        emit GuardianUpdatedHoldingAllocation(guardian, weth);
        vaultGuardians.updateHoldingAllocation(weth, newAllocationData);
        vm.stopPrank();
    }

    function testOnlyGuardianCanUpdateHoldingAllocation() public hasGuardian {
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(VaultGuardiansBase.VaultGuardiansBase__NotAGuardian.selector, user, weth)
        );
        vaultGuardians.updateHoldingAllocation(weth, newAllocationData);
        vm.stopPrank();
    }

    function testQuitGuardian() public hasGuardian {
        vm.startPrank(guardian);
        wethVaultShares.approve(address(vaultGuardians), mintAmount);
        vaultGuardians.quitGuardian();
        vm.stopPrank();

        assertEq(address(vaultGuardians.getVaultFromGuardianAndToken(guardian, weth)), address(0));
    }

    function testQuitGuardianEmitsEvent() public hasGuardian {
        vm.startPrank(guardian);
        wethVaultShares.approve(address(vaultGuardians), mintAmount);
        vm.expectEmit(false, false, false, true, address(vaultGuardians));
        emit GaurdianRemoved(guardian, weth);
        vaultGuardians.quitGuardian();
        vm.stopPrank();
    }

    function testBecomeTokenGuardian() public hasGuardian {
        usdc.mint(mintAmount, guardian);
        vm.startPrank(guardian);
        usdc.approve(address(vaultGuardians), mintAmount);
        address tokenVault = vaultGuardians.becomeTokenGuardian(allocationData, usdc);
        usdcVaultShares = VaultShares(tokenVault);
        vm.stopPrank();

        assertEq(address(vaultGuardians.getVaultFromGuardianAndToken(guardian, usdc)), tokenVault);
    }

    function testBecomeTokenGuardianOnlyApprovedTokens() public hasGuardian {
        ERC20Mock mockToken = new ERC20Mock();
        mockToken.mint(mintAmount, guardian);
        vm.startPrank(guardian);
        mockToken.approve(address(vaultGuardians), mintAmount);

        vm.expectRevert(
            abi.encodeWithSelector(VaultGuardiansBase.VaultGuardiansBase__NotApprovedToken.selector, address(mockToken))
        );
        vaultGuardians.becomeTokenGuardian(allocationData, mockToken);
        vm.stopPrank();
    }

    function testBecomeTokenGuardianTokenOneName() public hasGuardian {
        usdc.mint(mintAmount, guardian);
        vm.startPrank(guardian);
        usdc.approve(address(vaultGuardians), mintAmount);
        address tokenVault = vaultGuardians.becomeTokenGuardian(allocationData, usdc);
        usdcVaultShares = VaultShares(tokenVault);
        vm.stopPrank();

        assertEq(usdcVaultShares.name(), vaultGuardians.TOKEN_ONE_VAULT_NAME());
        assertEq(usdcVaultShares.symbol(), vaultGuardians.TOKEN_ONE_VAULT_SYMBOL());
    }

    function testBecomeTokenGuardianTokenTwoNameEmitsEvent() public hasGuardian {
        link.mint(mintAmount, guardian);
        vm.startPrank(guardian);
        link.approve(address(vaultGuardians), mintAmount);

        vm.expectEmit(false, false, false, true, address(vaultGuardians));
        emit GuardianAdded(guardian, link);
        vaultGuardians.becomeTokenGuardian(allocationData, link);
        vm.stopPrank();
    }

    modifier hasTokenGuardian() {
        usdc.mint(mintAmount, guardian);
        vm.startPrank(guardian);
        usdc.approve(address(vaultGuardians), mintAmount);
        address tokenVault = vaultGuardians.becomeTokenGuardian(allocationData, usdc);
        usdcVaultShares = VaultShares(tokenVault);
        vm.stopPrank();
        _;
    }

    function testCantQuitWethGuardianWithTokens() public hasGuardian hasTokenGuardian {
        vm.startPrank(guardian);
        usdcVaultShares.approve(address(vaultGuardians), mintAmount);
        vm.expectRevert(
            abi.encodeWithSelector(VaultGuardiansBase.VaultGuardiansBase__CantQuitWethWithThisFunction.selector)
        );
        vaultGuardians.quitGuardian(weth);
        vm.stopPrank();
    }

    function testCantQuitWethGuardianWithTokenQuit() public hasGuardian {
        vm.startPrank(guardian);
        wethVaultShares.approve(address(vaultGuardians), mintAmount);
        vm.expectRevert(
            abi.encodeWithSelector(VaultGuardiansBase.VaultGuardiansBase__CantQuitWethWithThisFunction.selector)
        );
        vaultGuardians.quitGuardian(weth);
        vm.stopPrank();
    }

    function testCantQuitWethWithOtherTokens() public hasGuardian hasTokenGuardian {
        vm.startPrank(guardian);
        usdcVaultShares.approve(address(vaultGuardians), mintAmount);
        vm.expectRevert(
            abi.encodeWithSelector(VaultGuardiansBase.VaultGuardiansBase__CantQuitWethWithThisFunction.selector)
        );
        vaultGuardians.quitGuardian();
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                               VIEW TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetVault() public hasGuardian hasTokenGuardian {
        assertEq(address(vaultGuardians.getVaultFromGuardianAndToken(guardian, weth)), address(wethVaultShares));
        assertEq(address(vaultGuardians.getVaultFromGuardianAndToken(guardian, usdc)), address(usdcVaultShares));
    }

    function testIsApprovedToken() public {
        assertEq(vaultGuardians.isApprovedToken(usdcAddress), true);
        assertEq(vaultGuardians.isApprovedToken(linkAddress), true);
        assertEq(vaultGuardians.isApprovedToken(wethAddress), true);
    }

    function testIsNotApprovedToken() public {
        ERC20Mock mock = new ERC20Mock();
        assertEq(vaultGuardians.isApprovedToken(address(mock)), false);
    }

    function testGetAavePool() public {
        assertEq(vaultGuardians.getAavePool(), aavePool);
    }

    function testGetUniswapV2Router() public {
        assertEq(vaultGuardians.getUniswapV2Router(), uniswapRouter);
    }

    function testGetGuardianStakePrice() public {
        assertEq(vaultGuardians.getGuardianStakePrice(), stakePrice);
    }

    function testGetGuardianDaoAndCut() public {
        assertEq(vaultGuardians.getGuardianAndDaoCut(), guardianAndDaoCut);
    }
}
