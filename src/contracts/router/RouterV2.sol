// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IUniswapV2Pair} from "src/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "src/interfaces/IUniswapV2Factory.sol";
import {IRouterV2} from "src/interfaces/IRouterV2.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UniswapV2Library} from "src/libraries/UniswapV2Library.sol";


contract RouterV2 is IRouterV2 {
    using SafeERC20 for IERC20;
    // using UniswapV2Library for IUniswapV2Factory;

    error RouterV2__AmountBelowMin(uint256 amount, uint256 minAmount);
    error RouterV2__AmountExceedMax(uint256 amount, uint256 maxAmount);
    error RouterV2__ReversedPairOrder();

    IUniswapV2Factory private s_factory;

    constructor(address _factory) {
        s_factory = IUniswapV2Factory(_factory);
    }

    function DepositLiquidityExact0(
        uint256 amount0,
        uint256 maxAmount1,
        address token0,
        address token1,
        address to
    ) external returns (uint256 shares) {
        address pair = s_factory.getPair(token0, token1);
        // if pair is zero create
        if(pair == address(0)) {
            s_factory.createPair(token0, token1);
        }

        (address token0Pair,) = IUniswapV2Pair(pair).getTokens();
        if(token0 != token0Pair) {
            revert RouterV2__ReversedPairOrder();
        }

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        uint256 amount1 = reserve0 > 0 && reserve1 > 0 ? (amount0 * reserve1) / reserve0 : maxAmount1;

        if(amount1 > maxAmount1) {
            revert RouterV2__AmountExceedMax(amount1, maxAmount1);
        }

        // Is there an MEV attack here if there use callback
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);

        return IUniswapV2Pair(pair).mint(to, amount0, amount1);
    }

    function DepositLiquidityExact1(
        uint256 maxAmount0,
        uint256 amount1,
        address token0,
        address token1,
        address to
    ) external returns (uint256 shares) {
        address pair = s_factory.getPair(token0, token1);
        // if pair is zero create
        if(pair == address(0)) {
            s_factory.createPair(token0, token1);
        }

        (address token0Pair,) = IUniswapV2Pair(pair).getTokens();
        if(token0 != token0Pair) {
            revert RouterV2__ReversedPairOrder();
        }

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        uint256 amount0 = reserve0 > 0 && reserve1 > 0 ? (amount1 * reserve0) / reserve1 : maxAmount0;

        if(amount0 > maxAmount0) {
            revert RouterV2__AmountExceedMax(amount0, maxAmount0);
        }

        // Is there an MEV attack here if there use callback
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);

        return IUniswapV2Pair(pair).mint(to, amount0, amount1);
    }

    function _swap(address[] memory path, address to) internal {
        for(uint256 i=0; i<path.length-1; i++) {
            (address input, address output) = (path[i], path[i+1]);
            (address token0,) = UniswapV2Library.sortTokens(s_factory, input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(s_factory.getPair(input, output));

            
            (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
            (uint256 reserveInputed, uint256 reserveOutputed) = token0 == input ? (reserve0, reserve1) : (reserve1, reserve0);

            uint256 amountInput = IERC20(input).balanceOf(address(pair)) - reserveInputed;
            uint256 amountOutput = UniswapV2Library.getAmountOut(pair, amountInput, reserveInputed, reserveOutputed);

            (uint256 amount0Out, uint256 amount1Out) = token0 == input ? (0, amountOutput) : (amountOutput, 0);

            address currenOutputReceiver = i < path.length - 2 ? s_factory.getPair(path[i+1], path[i+2]) : to;

            pair.swap(amount0Out, amount1Out, currenOutputReceiver, new bytes(0));
        }
    }

    function SwapExactInput(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] memory path,
        address to
    ) external {
        uint256 receiverBalance = IERC20(path[path.length-1]).balanceOf(to);

        IERC20(path[0]).safeTransfer(msg.sender, s_factory.getPair(path[0], path[1]), amountIn);

        _swap(path, to);

        uint256 newReceiverBalance = IERC20(path[path.length-1]).balanceOf(to);

        uint256 balanceReceived = newReceiverBalance - receiverBalance;

        if(balanceReceived < minAmountOut) {
            revert RouterV2__AmountBelowMin(balanceReceived, minAmountOut);
        }
    }

    function SwapExactOutput(
        uint256 maxAmountIn,
        uint256 amountOut,
        address[] memory path,
        address to
    ) external {
        uint256 amountIn = UniswapV2Library.getAmountsIn(s_factory, path, amountOut);
        if(amountIn > maxAmountIn) {
            revert RouterV2__AmountExceedMax(amountIn, maxAmountIn);
        }
        IERC20(path[1]).safeTransfer(msg.sender, s_factory.getPair(path[0], path[1]), amountIn);

        _swap(path, to);
    }

    function getFactory() external view returns (address) {
        return address(s_factory);
    }
}