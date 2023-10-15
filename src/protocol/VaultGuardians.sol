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
pragma solidity 0.8.18;

import {VaultShares} from "./VaultShares.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVaultData, IVaultShares} from "../interfaces/IVaultData.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VaultGuardians is Ownable, IVaultData {
    using SafeERC20 for IERC20;

    error VaultGuardians__NotEnoughWeth(uint256 amount, uint256 amountNeeded);

    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public constant GUARDIAN_STAKE_PRICE = 10 ether;
    mapping(address token => bool approved) public s_isApprovedToken;

    // The following four tokens are the approved tokens the protocol accepts
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    string private constant WETH_VAULT_NAME = "Vault Guardian WETH";
    string private constant WETH_VAULT_SYMBOL = "vgWETH";
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    string private constant USDC_VAULT_NAME = "Vault Guardian USDC";
    string private constant USDC_VAULT_SYMBOL = "vgUSDC";
    IERC20 public constant ADAI = IERC20(0x018008bfb33d285247A21d44E50697654f754e63);
    string private constant ADAI_VAULT_NAME = "Vault Guardian ADAI";
    string private constant ADAI_VAULT_SYMBOL = "vgADAI";
    IERC20 public constant LINK = IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);
    string private constant LINK_VAULT_NAME = "Vault Guardian LINK";
    string private constant LINK_VAULT_SYMBOL = "vgLINK";

    // The guardian's address mapped to the asset, mapped to the allocation data
    mapping(address guardianAddress => mapping(IERC20 asset => VaultData)) private s_guardians;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event VaultGuardians__GuardianAdded(address guardianAddress);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize() external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __VaultGuardians_init();
    }

    function __VaultGuardians_init() internal onlyInitializing {
        s_isApprovedToken[address(WETH)] = true;
        s_isApprovedToken[address(USDC)] = true;
        s_isApprovedToken[address(ADAI)] = true;
        s_isApprovedToken[address(LINK)] = true;
    }

    function becomeGuardian(AllocationData memory wethAllocationData) external {
        VaultShares wethVault =
            new VaultShares(WETH, WETH_VAULT_NAME, WETH_VAULT_SYMBOL, msg.sender, wethAllocationData);
        s_guardians[msg.sender][WETH] = VaultData(IVaultShares(address(wethVault)), wethAllocationData);
        wethVault.deposit(GUARDIAN_STAKE_PRICE, msg.sender);
        emit VaultGuardians__GuardianAdded(msg.sender);
    }

    function quitGuardian() external {}

    function updateHoldingAllocation() external {}

    function investInGuardian(address token) external {}

    function divestFromGuardian() external {}

    function migrateFromGuardian() external {}

    function getGuardian() external {}

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                   INTERNAL AND PRIVATE VIEW AND PURE
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                   EXTERNAL AND PUBLIC VIEW AND PURE
    //////////////////////////////////////////////////////////////*/

    function version() public pure returns (uint256) {
        return 1;
    }
}
