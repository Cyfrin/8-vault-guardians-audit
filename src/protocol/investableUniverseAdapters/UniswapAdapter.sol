// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IUniswapV2Router01} from "../../vendor/IUniswapV2Router01.sol";
import {IUniswapV2Factory} from "../../vendor/IUniswapV2Factory.sol";
import {AStaticUSDCData, IERC20} from "../../abstract/AStaticUSDCData.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapAdapter is AStaticUSDCData {
    using SafeERC20 for IERC20;

    IUniswapV2Router01 internal immutable i_uniswapRouter;
    IUniswapV2Factory internal immutable i_uniswapFactory;

    address[] private s_pathArray;

    event UniswapInvested(uint256 tokenAmount, uint256 wethAmount, uint256 liquidity);
    event UniswapDivested(uint256 tokenAmount, uint256 wethAmount);

    constructor(address uniswapRouter, address weth, address tokenOne) AStaticUSDCData(weth, tokenOne) {
        i_uniswapRouter = IUniswapV2Router01(uniswapRouter);
        i_uniswapFactory = IUniswapV2Factory(IUniswapV2Router01(i_uniswapRouter).factory());
    }

    function _uniswapInvest(IERC20 token, uint256 amount) internal {
        IERC20 counterPartyToken = token == i_weth ? i_tokenOne : i_weth;
        // We will do half in WETH and half in the token
        uint256 amountOfTokenToSwap = amount / 2;
        s_pathArray = [address(token), address(counterPartyToken)];

        token.approve(address(i_uniswapRouter), amountOfTokenToSwap);
        uint256[] memory amounts = i_uniswapRouter.swapExactTokensForTokens(
            amountOfTokenToSwap, 0, s_pathArray, address(this), block.timestamp
        );

        counterPartyToken.approve(address(i_uniswapRouter), amounts[1]);
        token.approve(address(i_uniswapRouter), amountOfTokenToSwap + amounts[0]);
        // amounts[1] should be the WETH amount we got back
        (uint256 tokenAmount, uint256 counterPartyTokenAmount, uint256 liquidity) = i_uniswapRouter.addLiquidity(
            address(token),
            address(counterPartyToken),
            amountOfTokenToSwap + amounts[0],
            amounts[1],
            0,
            0,
            address(this),
            block.timestamp
        );
        emit UniswapInvested(tokenAmount, counterPartyTokenAmount, liquidity);
    }

    function _uniswapDivest(IERC20 token, uint256 liquidityAmount) internal returns (uint256 amountOfAssetReturned) {
        IERC20 counterPartyToken = token == i_weth ? i_tokenOne : i_weth;

        (uint256 tokenAmount, uint256 counterPartyTokenAmount) = i_uniswapRouter.removeLiquidity(
            address(token), address(counterPartyToken), liquidityAmount, 0, 0, address(this), block.timestamp
        );
        s_pathArray = [address(counterPartyToken), address(token)];
        uint256[] memory amounts = i_uniswapRouter.swapExactTokensForTokens(
            counterPartyTokenAmount, 0, s_pathArray, address(this), block.timestamp
        );
        emit UniswapDivested(tokenAmount, amounts[1]);
        amountOfAssetReturned = amounts[1];
    }
}
