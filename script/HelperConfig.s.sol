// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants {
    uint256 constant LOCAL_CHAIN_ID = 31337;

    // Ethereum and its testnet
    uint256 constant MAINNET_ETHEREUM_CHAIN_ID = 1;
    uint256 constant SEPOLIA_ETHEREUM_CHAIN_ID = 11155111;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__ChainIdNotConfigured(uint256 chainId);
    struct NetworkConfig{
        address admin;
    }

    address constant ADMIN_ON_ETHEREUM_MAINNET = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    mapping(uint256 chainid => NetworkConfig) private s_configs;
    // NetworkConfig private s_localNetworkConfig;

    constructor() {
        s_configs[LOCAL_CHAIN_ID] = getLocalChainConfig();
        s_configs[MAINNET_ETHEREUM_CHAIN_ID] = getEthereumMainnetConfig();
        s_configs[SEPOLIA_ETHEREUM_CHAIN_ID] = getSepoliaConfig();
    }

    function getNetworkConfigByChainId(uint256 chainId) private view returns (NetworkConfig memory) {
        if(s_configs[chainId].admin != address(0)) {
            return s_configs[chainId];
        } else {
            revert HelperConfig__ChainIdNotConfigured(chainId);
        }
    }

    function getConfig() external view returns (NetworkConfig memory) {
        return getNetworkConfigByChainId(block.chainid);
    }

    function getSepoliaConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({
            admin: ADMIN_ON_ETHEREUM_MAINNET
        });
    }

    function getEthereumMainnetConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({
            admin: ADMIN_ON_ETHEREUM_MAINNET
        });
    }

    function getLocalChainConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({
            admin: ADMIN_ON_ETHEREUM_MAINNET

        });
    }
}