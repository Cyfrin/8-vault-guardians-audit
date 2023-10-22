// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {NetworkConfig} from "./NetworkConfig.s.sol";
import {VaultGuardians} from "../src/protocol/VaultGuardians.sol";
import {VaultGuardianGovernor} from "../src/dao/VaultGuardianGovernor.sol";
import {VaultGuardianToken} from "../src/dao/VaultGuardianToken.sol";

contract DeployVaultGuardians is Script {
    function run() external returns (VaultGuardians, VaultGuardianGovernor, VaultGuardianToken, NetworkConfig) {
        NetworkConfig networkConfig = new NetworkConfig(); // This comes with our mocks!
        (address aavePool, address uniswapRouter, address weth, address usdc, address link) =
            networkConfig.activeNetworkConfig();

        vm.startBroadcast();
        VaultGuardianToken vgToken = new VaultGuardianToken(); // mints us the total supply
        VaultGuardianGovernor vgGovernor = new VaultGuardianGovernor(vgToken);
        VaultGuardians vaultGuardians = new VaultGuardians(
            aavePool,
            uniswapRouter,
            weth,
            usdc,
            link, 
            address(vgToken)
        );
        vaultGuardians.transferOwnership(address(vgGovernor));
        vgToken.transferOwnership(address(vaultGuardians));
        vm.stopBroadcast();
        return (vaultGuardians, vgGovernor, vgToken, networkConfig);
    }

    // add this to be excluded from coverage report
    function test() public {}
}
