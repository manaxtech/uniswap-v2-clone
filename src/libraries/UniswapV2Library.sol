// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IUniswapV2Factory} from "src/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "src/interfaces/IUniswapV2Pair.sol";

library UniswapV2Library {
    error UniswapV2Library__NonExistentPair();

    function sortTokens(IUniswapV2Factory factory, address tokenA, address tokenB) internal view returns (address token0, address token1) {
        address pair = factory.getPair(tokenA, tokenB);
        if(pair != address(0)) {
            (token0, token1) = IUniswapV2Pair(pair).getTokens();
        } else {
            revert UniswapV2Library__NonExistentPair();
        }
    }

    function getAmountIn(IUniswapV2Pair pair, uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal view returns (uint256 amountIn) {
        (uint256 fee, uint256 precision) = pair.getFeeAndPrecision();

        // uint256 amount0In = balance0 > s_reserve0 ? (balance0 - s_reserve0) : 0;
        // uint256 amount1In = balance1 > s_reserve1 ? (balance1 - s_reserve1) : 0;

        // conventional calculation but Neither more accurate Nor more precise
        // uint256 k = s_reserve0 * s_reserve1;
        // uint256 k_new = ((s_reserve0+amount0InWithFee)-amount0Out) * ((s_reserve1+amount1InWithFee)-amount1Out);
        // {
        //     uint256 balance0Adjusted = (balance0 * PRECISION) - (amount0In * s_fee);
        //     uint256 balance1Adjusted = (balance1 * PRECISION) - (amount1In * s_fee);

        //     uint256 k = s_reserve0 * s_reserve1 * (1000**2);
        //     uint256 k_new = balance0Adjusted * balance1Adjusted;

    }
}