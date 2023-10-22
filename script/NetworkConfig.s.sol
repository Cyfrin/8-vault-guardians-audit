// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "../test/mocks/ERC20Mock.sol";
import {AavePoolMock} from "../test/mocks/AavePoolMock.sol";
import {UniswapFactoryMock} from "../test/mocks/UniswapFactoryMock.sol";
import {UniswapRouterMock} from "../test/mocks/UniswapRouterMock.sol";

contract NetworkConfig is Script {
    Config public activeNetworkConfig;

    struct Config {
        address aavePool;
        address uniswapRouter;
        address weth;
        address usdc;
        address link;
    }

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getMainnetEthConfig() public pure returns (Config memory) {
        return Config({
            aavePool: 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2,
            uniswapRouter: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            weth: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA
        });
    }

    function getOrCreateAnvilEthConfig() public returns (Config memory) {
        ERC20Mock weth = new ERC20Mock();
        ERC20Mock usdc = new ERC20Mock();
        ERC20Mock link = new ERC20Mock();

        AavePoolMock mAavePool = new AavePoolMock();
        UniswapFactoryMock mUniswapFactory = new UniswapFactoryMock();
        UniswapRouterMock mUniswapRouter = new UniswapRouterMock(address(mUniswapFactory), address(weth));

        return Config({
            aavePool: address(mAavePool),
            uniswapRouter: address(mUniswapRouter),
            weth: address(weth),
            usdc: address(usdc),
            link: address(link)
        });
    }

    // add this to be excluded from coverage report
    function test() public {}
}
