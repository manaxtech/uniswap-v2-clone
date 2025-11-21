// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IUniswapV2Factory} from "src/interfaces/IUniswapV2Factory.sol";
import {UniswapV2Pair} from "./UniswapV2Pair.sol";

contract UniswapV2Factory is IUniswapV2Factory {
    error UniswapV2Factory__NotAdmin();
    error UniswapV2Factory__IdenticalAddress();
    error UniswapV2Factory__PairAlreadyExist();
    error UniswapV2Factory__ZeroAddress();

    address private s_feeTo;
    address private s_admin;

    mapping(address token => mapping(address otherToken => address pair)) private s_pairs;
    address[] private s_allPairs;

    modifier onlyAdmin {
        if(msg.sender != s_admin) {
            revert UniswapV2Factory__NotAdmin();
        }
        _;
    }

    event PairCreated(address indexed token0, address indexed token1, address indexed pair, uint256 pairLength);

    constructor(address _admin) {
        s_admin = _admin;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        if(tokenA == tokenB) {
            revert UniswapV2Factory__IdenticalAddress();
        }
        if(tokenA == address(0) || tokenB == address(0)) {
            revert UniswapV2Factory__ZeroAddress();
        }
        if(s_pairs[tokenA][tokenB] != address(0)) {
            revert UniswapV2Factory__PairAlreadyExist();
        }
        // if(tokenB < tokenA) {
        //     (tokenA, tokenB) = (tokenB, tokenA);
        // }
        pair = address(new UniswapV2Pair(tokenA, tokenB));
        
        s_pairs[tokenA][tokenB] = pair;
        s_pairs[tokenB][tokenA] = pair;

        s_allPairs.push(pair);

        emit PairCreated(tokenA, tokenB, pair, s_allPairs.length);
    }

    function setFeeTo(address _feeTo) external onlyAdmin {
        s_feeTo = _feeTo;
    }
    
    function setAdmin(address _admin) external onlyAdmin {
        s_admin = _admin;
    }

    /**
     * 
     */
    function getFeeTo() external view returns (address) {
        return s_feeTo;
    }

    function getAdmin() external view returns (address) {
        return s_admin;
    }

    function getPair(address token, address otherToken) external view returns (address pair) {
        if(token == otherToken) {
            revert UniswapV2Factory__IdenticalAddress();
        }
        return s_pairs[token][otherToken];
    }

    function pairByIndex(uint256 index) external view returns (address pair) {
        return s_allPairs[index];
    }

    function allPairLength() external view returns (uint256 length) {
        return s_allPairs.length;
    }
    
}