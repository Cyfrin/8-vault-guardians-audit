/**
 *  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _
 * |_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_|
 * |_|                                                                                          |_|
 * |_| █████   █████                      ████   █████                                          |_|
 * |_|░░███   ░░███                      ░░███  ░░███                                           |_|
 * |_| ░███    ░███   ██████   █████ ████ ░███  ███████                                         |_|
 * |_| ░███    ░███  ░░░░░███ ░░███ ░███  ░███ ░░░███░                                          |_|
 * |_| ░░███   ███    ███████  ░███ ░███  ░███   ░███                                           |_|
 * |_|  ░░░█████░    ███░░███  ░███ ░███  ░███   ░███ ███                                       |_|
 * |_|    ░░███     ░░████████ ░░████████ █████  ░░█████                                        |_|
 * |_|     ░░░       ░░░░░░░░   ░░░░░░░░ ░░░░░    ░░░░░                                         |_|
 * |_|                                                                                          |_|
 * |_|                                                                                          |_|
 * |_|                                                                                          |_|
 * |_|   █████████                                     █████  ███                               |_|
 * |_|  ███░░░░░███                                   ░░███  ░░░                                |_|
 * |_| ███     ░░░  █████ ████  ██████   ████████   ███████  ████   ██████   ████████    █████  |_|
 * |_|░███         ░░███ ░███  ░░░░░███ ░░███░░███ ███░░███ ░░███  ░░░░░███ ░░███░░███  ███░░   |_|
 * |_|░███    █████ ░███ ░███   ███████  ░███ ░░░ ░███ ░███  ░███   ███████  ░███ ░███ ░░█████  |_|
 * |_|░░███  ░░███  ░███ ░███  ███░░███  ░███     ░███ ░███  ░███  ███░░███  ░███ ░███  ░░░░███ |_|
 * |_| ░░█████████  ░░████████░░████████ █████    ░░████████ █████░░████████ ████ █████ ██████  |_|
 * |_|  ░░░░░░░░░    ░░░░░░░░  ░░░░░░░░ ░░░░░      ░░░░░░░░ ░░░░░  ░░░░░░░░ ░░░░ ░░░░░ ░░░░░░   |_|
 * |_| _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _  _ |_|
 * |_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_||_|
 */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {VaultShares} from "./VaultShares.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVaultShares, IVaultData} from "../interfaces/IVaultShares.sol";
import {AStaticTokenData, IERC20} from "../abstract/AStaticTokenData.sol";
import {VaultGuardianToken} from "../dao/VaultGuardianToken.sol";

/*
 * @title VaultGuardiansBase
 * @author Vault Guardian
 * @notice This contract is the base contract for the VaultGuardians contract.
 * @notice it includes all the functionality of a user or guardian interacting with the protocol
 */

contract VaultGuardiansBase is AStaticTokenData, IVaultData {
    using SafeERC20 for IERC20;

    error VaultGuardiansBase__NotEnoughWeth(uint256 amount, uint256 amountNeeded);
    error VaultGuardiansBase__NotAGuardian(address guardianAddress, IERC20 token);
    error VaultGuardiansBase__CantQuitGuardianWithNonWethVaults(address guardianAddress);
    error VaultGuardiansBase__CantQuitWethWithThisFunction();
    error VaultGuardiansBase__TransferFailed();
    error VaultGuardiansBase__FeeTooSmall(uint256 fee, uint256 requiredFee);
    error VaultGuardiansBase__NotApprovedToken(address token);

    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address private immutable i_aavePool;
    address private immutable i_uniswapV2Router;
    VaultGuardianToken private immutable i_vgToken;

    uint256 private constant GUARDIAN_FEE = 0.1 ether;

    // DAO updatable values
    uint256 internal s_guardianStakePrice = 10 ether;
    uint256 internal s_guardianAndDaoCut = 1000;

    // The guardian's address mapped to the asset, mapped to the allocation data
    mapping(address guardianAddress => mapping(IERC20 asset => IVaultShares vaultShares)) private s_guardians;
    mapping(address token => bool approved) private s_isApprovedToken;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event GuardianAdded(address guardianAddress, IERC20 token);
    event GaurdianRemoved(address guardianAddress, IERC20 token);
    event InvestedInGuardian(address guardianAddress, IERC20 token, uint256 amount);
    event DinvestedFromGuardian(address guardianAddress, IERC20 token, uint256 amount);
    event GuardianUpdatedHoldingAllocation(address guardianAddress, IERC20 token);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyGuardian(IERC20 token) {
        if (address(s_guardians[msg.sender][token]) == address(0)) {
            revert VaultGuardiansBase__NotAGuardian(msg.sender, token);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(
        address aavePool,
        address uniswapV2Router,
        address weth,
        address tokenOne,
        address tokenTwo,
        address vgToken
    ) AStaticTokenData(weth, tokenOne, tokenTwo) {
        s_isApprovedToken[weth] = true;
        s_isApprovedToken[tokenOne] = true;
        s_isApprovedToken[tokenTwo] = true;

        i_aavePool = aavePool;
        i_uniswapV2Router = uniswapV2Router;
        i_vgToken = VaultGuardianToken(vgToken);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /*
     * @notice allows a user to become a guardian
     * @notice they have to send an ETH amount equal to the fee, and a WETH amount equal to the stake price
     * 
     * @param wethAllocationData the allocation data for the WETH vault
     */
    function becomeGuardian(AllocationData memory wethAllocationData) external returns (address) {
        VaultShares wethVault =
        new VaultShares(IVaultShares.ConstructorData({
            asset: i_weth,
            vaultName: WETH_VAULT_NAME,
            vaultSymbol: WETH_VAULT_SYMBOL,
            guardian: msg.sender,
            allocationData: wethAllocationData,
            aavePool: i_aavePool,
            uniswapRouter: i_uniswapV2Router,
            guardianAndDaoCut: s_guardianAndDaoCut,
            vaultGuardians: address(this),
            weth: address(i_weth),
            usdc: address(i_tokenOne)
        }));
        return _becomeTokenGuardian(i_weth, wethVault);
    }

    function becomeTokenGuardian(AllocationData memory allocationData, IERC20 token)
        external
        onlyGuardian(i_weth)
        returns (address)
    {
        //slither-disable-next-line uninitialized-local
        VaultShares tokenVault;
        if (address(token) == address(i_tokenOne)) {
            tokenVault =
            new VaultShares(IVaultShares.ConstructorData({
                asset: token,
                vaultName: TOKEN_ONE_VAULT_NAME,
                vaultSymbol: TOKEN_ONE_VAULT_SYMBOL,
                guardian: msg.sender,
                allocationData: allocationData,
                aavePool: i_aavePool,
                uniswapRouter: i_uniswapV2Router,
                guardianAndDaoCut: s_guardianAndDaoCut,
                vaultGuardians: address(this),
                weth: address(i_weth),
                usdc: address(i_tokenOne)
            }));
        } else if (address(token) == address(i_tokenTwo)) {
            tokenVault =
            new VaultShares(IVaultShares.ConstructorData({
                asset: token,
                vaultName: TOKEN_ONE_VAULT_NAME,
                vaultSymbol: TOKEN_ONE_VAULT_SYMBOL,
                guardian: msg.sender,
                allocationData: allocationData,
                aavePool: i_aavePool,
                uniswapRouter: i_uniswapV2Router,
                guardianAndDaoCut: s_guardianAndDaoCut,
                vaultGuardians: address(this),
                weth: address(i_weth),
                usdc: address(i_tokenOne)
            }));
        } else {
            revert VaultGuardiansBase__NotApprovedToken(address(token));
        }
        return _becomeTokenGuardian(token, tokenVault);
    }

    /*
     * @notice allows a guardian to quit
     * @dev this will only work if they only have a WETH vault left, a guardian can't quit if they have other vaults
     * @dev they will need to approve this contract to spend their shares tokens
     * @dev this will set the vault to no longer be active, meaning users can only withdraw tokens, and no longer deposit to the vault
     * @dev tokens should also no longer be invested into the protocols
     */
    function quitGuardian() external onlyGuardian(i_weth) returns (uint256) {
        if (_guardianHasNonWethVaults(msg.sender)) {
            revert VaultGuardiansBase__CantQuitWethWithThisFunction();
        }
        return _quitGuardian(i_weth);
    }

    /*
     * See VaultGuardiansBase::quitGuardian()
     * The only difference here, is that this function is for non-WETH vaults
     */
    function quitGuardian(IERC20 token) external onlyGuardian(token) returns (uint256) {
        if (token == i_weth) {
            revert VaultGuardiansBase__CantQuitWethWithThisFunction();
        }
        return _quitGuardian(token);
    }

    function updateHoldingAllocation(IERC20 token, AllocationData memory tokenAllocationData)
        external
        onlyGuardian(token)
    {
        emit GuardianUpdatedHoldingAllocation(msg.sender, token);
        s_guardians[msg.sender][token].updateHoldingAllocation(tokenAllocationData);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _quitGuardian(IERC20 token) private returns (uint256) {
        IVaultShares tokenVault = IVaultShares(s_guardians[msg.sender][token]);
        s_guardians[msg.sender][token] = IVaultShares(address(0));
        emit GaurdianRemoved(msg.sender, token);
        tokenVault.setNotActive();
        uint256 maxRedeemable = tokenVault.maxRedeem(msg.sender);
        uint256 numberOfAssetsReturned = tokenVault.redeem(maxRedeemable, msg.sender, msg.sender);
        return numberOfAssetsReturned;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _guardianHasNonWethVaults(address guardian) private view returns (bool) {
        if (address(s_guardians[guardian][i_tokenOne]) != address(0)) {
            return true;
        } else {
            return address(s_guardians[guardian][i_tokenTwo]) != address(0);
        }
    }

    // slither-disable-start reentrancy-eth
    /*
     * @notice allows a user to become a guardian
     * @notice guardians are given a VaultGuardianToken as payment
     * @param token the token that the guardian will be guarding
     * @param tokenVault the vault that the guardian will be guarding
     */
    function _becomeTokenGuardian(IERC20 token, VaultShares tokenVault) private returns (address) {
        s_guardians[msg.sender][token] = IVaultShares(address(tokenVault));
        emit GuardianAdded(msg.sender, token);
        i_vgToken.mint(msg.sender, s_guardianStakePrice);
        token.safeTransferFrom(msg.sender, address(this), s_guardianStakePrice);
        bool succ = token.approve(address(tokenVault), s_guardianStakePrice);
        if (!succ) {
            revert VaultGuardiansBase__TransferFailed();
        }
        uint256 shares = tokenVault.deposit(s_guardianStakePrice, msg.sender);
        if (shares == 0) {
            revert VaultGuardiansBase__TransferFailed();
        }
        return address(tokenVault);
    }
    // slither-disable-end reentrancy-eth

    /*//////////////////////////////////////////////////////////////
                   INTERNAL AND PRIVATE VIEW AND PURE
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                   EXTERNAL AND PUBLIC VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    function getVaultFromGuardianAndToken(address guardian, IERC20 token) external view returns (IVaultShares) {
        return s_guardians[guardian][token];
    }

    function isApprovedToken(address token) external view returns (bool) {
        return s_isApprovedToken[token];
    }

    function getAavePool() external view returns (address) {
        return i_aavePool;
    }

    function getUniswapV2Router() external view returns (address) {
        return i_uniswapV2Router;
    }

    function getGuardianStakePrice() external view returns (uint256) {
        return s_guardianStakePrice;
    }

    function getGuardianAndDaoCut() external view returns (uint256) {
        return s_guardianAndDaoCut;
    }
}
