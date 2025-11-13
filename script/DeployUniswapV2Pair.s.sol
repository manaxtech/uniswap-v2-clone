// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script} from "forge-std/Script.sol";
import {UniswapV2Pair} from "../src/core/UniswapV2Pair.sol";

contract DeployUniswapV2Pair is Script {
    function run(address token0, address token1) external returns (address) {
        vm.startBroadcast();
        UniswapV2Pair pair = new UniswapV2Pair(token0, token1);
        vm.stopBroadcast();

        return address(pair);
    }
}