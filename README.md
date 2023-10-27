# Vault Guardians

<p align="center">
<img src="./vault-guardians.png" width="400" alt="vault-guardians">
</p>

- [Vault Guardians](#vault-guardians)
  - [About](#about)
  - [User flow](#user-flow)
  - [The DAO](#the-dao)
  - [Summary](#summary)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
    - [Optional Gitpod](#optional-gitpod)
- [Usage](#usage)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
- [Misc](#misc)
- [Audit Scope Details](#audit-scope-details)

## About

This protocol allows users to deposit certain ERC20s into an [ERC4626 vault](https://eips.ethereum.org/EIPS/eip-4626) managed by a human being, or a `vaultGuardian`. The goal of a `vaultGuardian` is to manage the vault in a way that maximizes the value of the vault for the users who have despoited money into the vault.

You can think of a `vaultGuardian` as a fund manager.

To prevent a vault guardian from running off with the funds, the vault guardians are only allowed to deposit and withdraw the ERC20s into specific protocols. 

- [Aave v3](https://aave.com/) 
- [Uniswap v2](https://uniswap.org/) 
- None (just hold) 

These 2 protocols (plus "none" makes 3) are known as the "investable universe".

The guardian can move funds in and out of these protocols as much as they like, but they cannot move funds to any other address.

The goal of a vault guardian, is to move funds in and out of these protocols to gain the most yield. Vault guardians charge a performance fee, the better the guardians do, the larger fee they will earn. 

Anyone can become a Vault Guardian by depositing a certain amount of the ERC20 into the vault. This is called the `guardian stake`. If a guardian wishes to stop being a guardian, they give out all user deposits and withdraw their guardian stake.

Users can then move their funds between vault managers as they see fit. 

The protocol is upgradeable so that if any of the platforms in the investable universe change, or we want to add more, we can do so.

## User flow

1. User deposits an ERC20 into a guardian's vault
2. The guardian automatically move the funds based on their strategy 
3. The guardian can update the settings of their strategy at any time and move the funds
4. To leave the pool, a user just calls `redeem` or `withdraw`

## The DAO

Guardians can earn DAO tokens by becoming guardians. The DAO is responsible for:
- Updating pricing parameters
- Getting a cut of all performance of all guardians

## Summary

Users can stake some ERC20s to become a vault guardian. Other users can allocate them funds in order to maximize yield. The guardians can move the funds between Uniswap, Aave, or just hold the funds. The guardians are incentivized to maximize yield, as they earn a performance fee.

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```
git clone https://github.com/Cyfrin/8-vault-guardians-audit
cd 8-vault-guardians-audit
make 
```

### Optional Gitpod

If you can't or don't want to run and install locally, you can work with this repo in Gitpod. If you do this, you can skip the `clone this repo` part.

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#github.com/Cyfrin/8-vault-guardians-audit)

# Usage

## Testing

Set the `RPC_URL_MAINNET` environment variable with the URL of a mainnet RPC node. It's used for tests that fork Ethereum mainnet state.

Then run:

```
forge test
```

### Test Coverage

```
forge coverage
```

and for coverage based testing: 

```
forge coverage --report debug
```

# Misc

- [Art made with asciiart.eu](https://www.asciiart.eu/text-to-ascii-art)
- [headers from t11/headers](https://github.com/transmissions11/headers)

# Audit Scope Details

- Commit Hash: xx
- In Scope:
```

```
- Solc Version: 0.8.20
- Chain(s) to deploy contract to: Ethereum
- Tokens:
  - weth: https://etherscan.io/token/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
  - link: https://etherscan.io/token/0x514910771af9ca656af840dff83e8264ecf986ca
  - usdc: https://etherscan.io/token/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48

# Known issues 
- All issues in the `audit-data` folder are considered known
- We are aware that USDC is behind a proxy and is susceptible to being paused and upgraded. Please assume for this audit that is not the case.  

