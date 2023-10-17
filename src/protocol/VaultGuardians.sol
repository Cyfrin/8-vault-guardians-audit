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
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AStaticTokenData, IERC20} from "../abstract/AStaticTokenData.sol";

contract VaultGuardians is Ownable, AStaticTokenData, IVaultData {
    using SafeERC20 for IERC20;

    error VaultGuardians__NotEnoughWeth(uint256 amount, uint256 amountNeeded);
    error VaultGuardians__NotAGuardian(address guardianAddress, IERC20 token);
    error VaultGuardians__CantQuitGuardianWithNonWethVaults(address guardianAddress);
    error VaultGuardians__CantQuitWethWithThisFunction();
    error VaultGuardians__TransferFailed();

    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address private immutable i_aavePool;
    address private immutable i_uniswapV2Router;

    uint256 public constant GUARDIAN_STAKE_PRICE = 10 ether;
    mapping(address token => bool approved) public s_isApprovedToken;

    // The guardian's address mapped to the asset, mapped to the allocation data
    mapping(address guardianAddress => mapping(IERC20 asset => IVaultShares vaultShares)) private s_guardians;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event GuardianAdded(address guardianAddress);
    event GaurdianRemoved(address guardianAddress);
    event InvestedInGuardian(address guardianAddress, IERC20 token, uint256 amount);
    event DinvestedFromGuardian(address guardianAddress, IERC20 token, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyGuardian(IERC20 token) {
        if (address(s_guardians[msg.sender][token]) == address(0)) {
            revert VaultGuardians__NotAGuardian(msg.sender, token);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(address aavePool, address uniswapV2Router) Ownable(msg.sender) {
        s_isApprovedToken[address(WETH)] = true;
        s_isApprovedToken[address(USDC)] = true;
        s_isApprovedToken[address(ADAI)] = true;
        s_isApprovedToken[address(LINK)] = true;

        i_aavePool = aavePool;
        i_uniswapV2Router = uniswapV2Router;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function becomeGuardian(AllocationData memory wethAllocationData) external {
        VaultShares wethVault =
        new VaultShares(WETH, WETH_VAULT_NAME, WETH_VAULT_SYMBOL, msg.sender, wethAllocationData, i_aavePool, i_uniswapV2Router);

        s_guardians[msg.sender][WETH] = IVaultShares(address(wethVault));
        wethVault.deposit(GUARDIAN_STAKE_PRICE, msg.sender);
        emit GuardianAdded(msg.sender);
    }

    function quitGuardian() external onlyGuardian(WETH) {
        if (_guardianHasNonWethVaults(msg.sender)) {
            revert VaultGuardians__CantQuitWethWithThisFunction();
        }
        IVaultShares wethVault = IVaultShares(s_guardians[msg.sender][WETH]);
        uint256 maxRedeemable = wethVault.maxRedeem(msg.sender);
        /* uint256 numberOfAssetsReturned = */
        wethVault.redeem(maxRedeemable, msg.sender, msg.sender);
        s_guardians[msg.sender][WETH] = IVaultShares(address(0));
        emit GaurdianRemoved(msg.sender);
    }

    function quitGuardian(IERC20 token) external onlyGuardian(token) {
        if (token == WETH) {
            revert VaultGuardians__CantQuitWethWithThisFunction();
        }
        IVaultShares tokenhVault = IVaultShares(s_guardians[msg.sender][token]);
        uint256 maxRedeemable = tokenhVault.maxRedeem(msg.sender);
        /* uint256 numberOfAssetsReturned = */
        tokenhVault.redeem(maxRedeemable, msg.sender, msg.sender);
        s_guardians[msg.sender][WETH] = IVaultShares(address(0));
        emit GaurdianRemoved(msg.sender);
    }

    function updateHoldingAllocation(IERC20 token, AllocationData memory tokenAllocationData) external {
        s_guardians[msg.sender][token].updateHoldingAllocation(tokenAllocationData);
    }

    function investInGuardian(IERC20 token, uint256 amount) external {
        IVaultShares vaultShares = s_guardians[msg.sender][token];
        vaultShares.deposit(amount, msg.sender);
        emit InvestedInGuardian(msg.sender, token, amount);
    }

    function divestFromGuardian(IERC20 token) external {
        IVaultShares vaultShares = s_guardians[msg.sender][token];
        uint256 maxRedeemable = vaultShares.maxRedeem(msg.sender);
        uint256 numberOfAssetsReturned = vaultShares.redeem(maxRedeemable, msg.sender, msg.sender);
        emit DinvestedFromGuardian(msg.sender, token, numberOfAssetsReturned);
    }

    /*
     * @notice Any excess ERC20s can be scooped up by the DAO. 
     * @notice This is often just little bits left around from swapping or rounding errors
     * @dev Since this is owned by the DAO, the funds will always go to the DAO. 
     * @params asset The ERC20 to sweep
     */
    function sweepErc20s(IERC20 asset) external onlyOwner {
        uint256 amount = asset.balanceOf(address(this));
        asset.safeTransfer(owner(), amount);
    }

    /*
     * @notice Any excess ETH can be scooped up by the DAO. 
     * @notice This is often just little bits left around from swapping or rounding errors
     * @dev Since this is owned by the DAO, the funds will always go to the DAO. 
     */
    function sweepEth() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = payable(owner()).call{value: amount}("");
        if (!success) {
            revert VaultGuardians__TransferFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _guardianHasNonWethVaults(address guardian) private view returns (bool) {
        if (address(s_guardians[guardian][USDC]) != address(0)) {
            return true;
        } else if (address(s_guardians[guardian][ADAI]) != address(0)) {
            return true;
        } else {
            return address(s_guardians[guardian][LINK]) != address(0);
        }
    }
    /*//////////////////////////////////////////////////////////////
                   INTERNAL AND PRIVATE VIEW AND PURE
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                   EXTERNAL AND PUBLIC VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    function getGuardianAllocations(address guardian, IERC20 token) external view returns (IVaultShares) {
        return s_guardians[guardian][token];
    }
}
