// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPool, DataTypes} from "../../src/vendor/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AavePoolMock is IPool {
    mapping(address => address) public s_assetToAtoken;

    function updateAtokenAddress(address asset, address aToken) public {
        s_assetToAtoken[asset] = aToken;
    }

    function supply(address asset, uint256 amount, address, /* onBehalfOf */ uint16 /* referralCode */ ) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        IERC20(asset).transfer(to, amount);
        return amount;
    }

    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory) {
        DataTypes.ReserveConfigurationMap memory map = DataTypes.ReserveConfigurationMap({data: 0});
        return DataTypes.ReserveData({
            //stores the reserve configuration
            configuration: map,
            //the liquidity index. Expressed in ray
            liquidityIndex: 0,
            //the current supply rate. Expressed in ray
            currentLiquidityRate: 0,
            //variable borrow index. Expressed in ray
            variableBorrowIndex: 0,
            //the current variable borrow rate. Expressed in ray
            currentVariableBorrowRate: 0,
            //the current stable borrow rate. Expressed in ray
            currentStableBorrowRate: 0,
            //timestamp of last update
            lastUpdateTimestamp: 0,
            //the id of the reserve. Represents the position in the list of the active reserves
            id: 0,
            //aToken address
            aTokenAddress: s_assetToAtoken[asset],
            //stableDebtToken address
            stableDebtTokenAddress: address(0),
            //variableDebtToken address
            variableDebtTokenAddress: address(0),
            //address of the interest rate strategy
            interestRateStrategyAddress: address(0),
            //the current treasury balance, scaled
            accruedToTreasury: 0,
            //the outstanding unbacked aTokens minted through the bridging feature
            unbacked: 0,
            //the outstanding debt borrowed against this asset in isolation mode
            isolationModeTotalDebt: 0
        });
    }

    // add this to be excluded from coverage report
    function test() public {}
}
