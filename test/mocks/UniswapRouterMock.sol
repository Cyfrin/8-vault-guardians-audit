// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "./ERC20Mock.sol";
import {IUniswapV2Router01} from "../../src/vendor/IUniswapV2Router01.sol";

contract UniswapRouterMock is IUniswapV2Router01, ERC20Mock {
    address s_factory;
    address s_weth;

    constructor(address newFactory, address weth) {
        s_factory = newFactory;
        s_weth = weth;
    }

    function updateFactory(address newFactory) public {
        s_factory = newFactory;
    }

    function factory() external view returns (address) {
        return s_factory;
    }

    function WETH() external view returns (address) {
        return s_weth;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256,
        uint256,
        address,
        uint256
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        ERC20Mock(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        ERC20Mock(tokenB).transferFrom(msg.sender, address(this), amountBDesired);
        _mint(msg.sender, liquidity);
        return (amountADesired, amountBDesired, 0);
    }

    function removeLiquidity(address tokenA, address tokenB, uint256, uint256, uint256, address to, uint256)
        external
        returns (uint256 amountA, uint256 amountB)
    {
        uint256 tokenABalance = ERC20Mock(tokenA).balanceOf(address(this));
        uint256 tokenBBalance = ERC20Mock(tokenB).balanceOf(address(this));

        ERC20Mock(tokenA).transfer(to, tokenABalance);
        ERC20Mock(tokenB).transfer(to, tokenBBalance);
        return (tokenABalance, tokenBBalance);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256
    ) external returns (uint256[] memory amounts) {
        ERC20Mock(path[0]).transferFrom(msg.sender, address(this), amountInMax);
        ERC20Mock(path[1]).mint(amountOut, to);
        amounts = new uint256[](2);
        amounts[0] = amountInMax;
        amounts[1] = amountOut;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256
    ) external returns (uint256[] memory amounts) {
        ERC20Mock(path[0]).transferFrom(msg.sender, address(this), amountIn);
        ERC20Mock(path[1]).mint(amountOutMin, to);
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOutMin;
    }

    // add this to be excluded from coverage report
    function testA() public {}
}
