// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {ERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IUniswapV2Callback} from "./interfaces/IUniswapV2Callback.sol";

import {console2} from "forge-std/console2.sol";

contract UniswapV2Pair is IUniswapV2Pair, ERC20, ReentrancyGuard{
    using SafeERC20 for IERC20;

    error UniswapV2Pair__InsufficientOutput();
    error UniswapV2Pair__CanNotOutputTwoTokens();
    error UniswapV2Pair__K();

    uint256 private constant FEE = 3;
    uint256 private constant PRECISION = 1000;

    IERC20 s_token0;
    IERC20 s_token1;

    uint256 private s_reserve0;
    uint256 private s_reserve1;
    uint48 private s_lastTimestamp;

    event Swap(
        address indexed sender,
        address indexed to,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    );

    constructor(address token0, address token1)
    ERC20(
        string.concat(IERC20Metadata(token0).name(), " and ", IERC20Metadata(token1).name(), " UniswapV2Pair"),
        string.concat(IERC20Metadata(token0).symbol(), "/", IERC20Metadata(token1).symbol(), " UNI-V2")
    ) {
        s_token0 = IERC20(token0);
        s_token1 = IERC20(token1);
    }

    /**
     * @dev this function swap, you specify how much of either token you want to get and you transfer the corresponding amount of other token
     * @dev Use the constant product formula to calculate how much token you transfer
     * @param amount0Out amount of token0 to get from the pair
     * @param amount1Out amount of token1 to get from the pair
     */
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external nonReentrant {
        if(amount0Out == 0 && amount1Out == 0) {
            revert UniswapV2Pair__InsufficientOutput();
        }

        if(amount0Out > 0 && amount1Out > 0) {
            revert UniswapV2Pair__CanNotOutputTwoTokens();
        }

        if (amount0Out > 0) s_token0.safeTransfer(to, amount0Out);
        if (amount1Out > 0) s_token1.safeTransfer(to, amount1Out);
        
        if(data.length > 0) IUniswapV2Callback(msg.sender).uniswapV2Callback(to, amount0Out, amount1Out, data);
        
        uint256 balance0 = s_token0.balanceOf(address(this));
        uint256 balance1 = s_token1.balanceOf(address(this));

        // conventional calculation but Neither more accurate nor more precise
        // uint256 amount0InWithFee = balance0 > s_reserve0 ? ((balance0 - s_reserve0)*WITH_FEE)/PRECISION : 0;
        // uint256 amount1InWithFee = balance1 > s_reserve1 ? ((balance1 - s_reserve1)*WITH_FEE)/PRECISION: 0;
        uint256 amount0In = balance0 > s_reserve0 ? (balance0 - s_reserve0) : 0;
        uint256 amount1In = balance1 > s_reserve1 ? (balance1 - s_reserve1) : 0;

        // conventional calculation but Neither more accurate Nor more precise
        // uint256 k = s_reserve0 * s_reserve1;
        // uint256 k_new = ((s_reserve0+amount0InWithFee)-amount0Out) * ((s_reserve1+amount1InWithFee)-amount1Out);
        {
            uint256 balance0Adjusted = (balance0 * PRECISION) - (amount0In * FEE);
            uint256 balance1Adjusted = (balance1 * PRECISION) - (amount1In * FEE);

            uint256 k = s_reserve0 * s_reserve1 * (1000**2);
            uint256 k_new = balance0Adjusted * balance1Adjusted;

            if(k > k_new) {
                revert UniswapV2Pair__K();
            }
        }

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // NEVER FORGET TO UPDATE RESERVE 0 AND 1*****************************************************************************************************
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        emit Swap(msg.sender, to, amount0In, amount1In, amount0Out, amount1Out);
    }

    function setReserve(uint256 _reserve0, uint256 _reserve1) external {
        s_reserve0 += _reserve0;
        s_reserve1 += _reserve1;
        
        s_token0.safeTransferFrom(msg.sender, address(this), _reserve0);
        s_token1.safeTransferFrom(msg.sender, address(this), _reserve1);
    }

    /**
     * @dev returns both reserve value and last time they were updated
     * @return _reserve0 is the amount of token0 that are in first reserve(s_reserve0)
     * @return _reserve1 is the amount of token1 that are in second reserve(s_reserve1)
     * @return _lastTimestamp is last timestamp where s_reserve0 and s_resevrve1 updated
     */
    function getReserves() public view returns(uint256 _reserve0, uint256 _reserve1, uint48 _lastTimestamp) {
        _reserve0 = s_reserve0;
        _reserve1 = s_reserve1;
        _lastTimestamp = s_lastTimestamp;
    }

    /**
     * @dev returns both token that can be swapped
     * @return _token0 is address of the first token(s_token0)
     * @return _token1 is address of the second token(s_token1)
     */
    function getTokens() external view returns(address _token0, address _token1) {
        _token0 = address(s_token0);
        _token1 = address(s_token1);
    }

}