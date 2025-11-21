// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IUniswapV2Pair {
    function mint(address to, uint256 _token0Amount, uint256 _token1Amount) external returns (uint256 liquidity);

    function burn(uint256 burnAmount) external;
    
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function getReserves() external view returns(uint256 _reserve0, uint256 _reserve1, uint48 _lastTimestamp);

    function getTokens() external view returns(address _token0, address _token1);

    function getFeeAndPrecision() external view returns (uint256 fee, uint256 precision);
}