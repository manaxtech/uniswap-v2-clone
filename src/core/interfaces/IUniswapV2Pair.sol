// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IUniswapV2Pair {
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function getReserves() external view returns(uint256 _reserve0, uint256 _reserve1, uint48 _lastTimestamp);

    function getTokens() external view returns(address _token0, address _token1);
}