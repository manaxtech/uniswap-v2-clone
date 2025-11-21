// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address _feeTo) external;
    
    function setAdmin(address _admin) external;

    function getFeeTo() external view returns (address);

    function getAdmin() external view returns (address);

    function getPair(address token, address otherToken) external view returns (address pair);

    function pairByIndex(uint256 index) external view returns (address pair);

    function allPairLength() external view returns (uint256 length);
    
}