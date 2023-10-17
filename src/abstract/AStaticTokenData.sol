// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract AStaticTokenData {
    // The following four tokens are the approved tokens the protocol accepts
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    string internal constant WETH_VAULT_NAME = "Vault Guardian WETH";
    string internal constant WETH_VAULT_SYMBOL = "vgWETH";
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    string internal constant USDC_VAULT_NAME = "Vault Guardian USDC";
    string internal constant USDC_VAULT_SYMBOL = "vgUSDC";
    IERC20 public constant ADAI = IERC20(0x018008bfb33d285247A21d44E50697654f754e63);
    string internal constant ADAI_VAULT_NAME = "Vault Guardian ADAI";
    string internal constant ADAI_VAULT_SYMBOL = "vgADAI";
    IERC20 public constant LINK = IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);
    string internal constant LINK_VAULT_NAME = "Vault Guardian LINK";
    string internal constant LINK_VAULT_SYMBOL = "vgLINK";
}
