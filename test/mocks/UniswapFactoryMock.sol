// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Factory} from "../../src/vendor/IUniswapV2Factory.sol";

contract UniswapFactoryMock is IUniswapV2Factory {
    address zero = address(0);
    uint256 zero_value = 0;
    uint256 doSomething = 0;

    address pairToReturn;

    function updatePairToReturn(address pair) public {
        pairToReturn = pair;
    }

    function updatePairsAddress() public {}

    function feeTo() external view returns (address) {
        return zero;
    }

    function feeToSetter() external view returns (address) {
        return zero;
    }

    function getPair(address, /*tokenA*/ address /*tokenB*/ ) external view returns (address pair) {
        return pairToReturn;
    }

    function allPairs(uint256) external view returns (address pair) {}

    function allPairsLength() external view returns (uint256) {
        return zero_value;
    }

    function createPair(address, /* tokenA */ address /* tokenB */ ) external returns (address pair) {
        doSomething = doSomething + 1;
        return zero;
    }

    function setFeeTo(address) external {}
    function setFeeToSetter(address) external {}

    // add this to be excluded from coverage report
    function test() public {}
}
