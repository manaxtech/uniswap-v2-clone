// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script} from "forge-std/Script.sol";
import {UniswapV2Factory} from "src/contracts/core/UniswapV2Factory.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployUniswapV2Factory is Script {

    function run() external returns (address) {
        HelperConfig helperConfig = new HelperConfig();
        address admin = helperConfig.getConfig().admin;

        vm.startBroadcast();
        UniswapV2Factory factory = new UniswapV2Factory(admin);
        vm.stopBroadcast();

        return address(factory);
    }
}