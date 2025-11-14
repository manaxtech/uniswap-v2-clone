// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

interface IUniswapV2Callback {
    function uniswapV2Callback(address receiver, uint256 amount0Out, uint256 amount1Out, bytes calldata data) external;
}