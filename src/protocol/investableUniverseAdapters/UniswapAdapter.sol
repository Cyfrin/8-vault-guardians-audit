// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IUniswapV2Router01} from "../../vendor/IUniswapV2Router01.sol";
import {IUniswapV2Factory} from "../../vendor/IUniswapV2Factory.sol";
import {AStaticTokenData, IERC20} from "../../abstract/AStaticTokenData.sol";

contract UniswapAdapter is AStaticTokenData {
    IUniswapV2Router01 internal immutable i_uniswapRouter;
    IUniswapV2Factory internal immutable i_uniswapFactory;

    address[] private pathArray;

    event UniswapInvested(uint256 tokenAmount, uint256 wethAmount, uint256 liquidity);
    event UniswapDivested(uint256 tokenAmount, uint256 wethAmount);

    constructor(address uniswapRouter) {
        i_uniswapRouter = IUniswapV2Router01(uniswapRouter);
        i_uniswapFactory = IUniswapV2Factory(IUniswapV2Router01(i_uniswapRouter).factory());
    }

    function uniswapInvest(IERC20 token, uint256 amount) internal {
        // We will do half in WETH and half in the token
        uint256 amountOfTokenToSwap = amount / 2;
        pathArray = [address(token), address(WETH)];
        uint256[] memory amounts =
            i_uniswapRouter.swapExactTokensForTokens(amountOfTokenToSwap, 0, pathArray, address(this), block.timestamp);
        // amounts[1] should be the WETH amount we got back
        (uint256 tokenAmount, uint256 wethAmount, uint256 liquidity) = i_uniswapRouter.addLiquidity(
            address(token),
            address(WETH),
            amountOfTokenToSwap + amounts[0],
            amounts[1],
            0,
            0,
            address(this),
            block.timestamp
        );
        emit UniswapInvested(tokenAmount, wethAmount, liquidity);
    }

    function uniswapDivest(IERC20 token, uint256 liquidityAmount) internal returns (uint256 amountOfAssetReturned) {
        (uint256 tokenAmount, uint256 wethAmount) = i_uniswapRouter.removeLiquidity(
            address(token), address(WETH), liquidityAmount, 0, 0, address(this), block.timestamp
        );
        pathArray = [address(WETH), address(token)];
        uint256[] memory amounts =
            i_uniswapRouter.swapExactTokensForTokens(wethAmount, 0, pathArray, address(this), block.timestamp);
        emit UniswapDivested(tokenAmount, amounts[1]);
        amountOfAssetReturned = amounts[1];
    }
}
