// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {ERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapV2Pair is IUniswapV2Pair, ERC20{
    using SafeERC20 for IERC20;

    IERC20 s_token0;
    IERC20 s_token1;

    uint112 private s_reserve0;
    uint112 private s_reserve1;
    uint48 private s_lastTimestamp;

    constructor(address token0, address token1)
    ERC20(
        string.concat(IERC20Metadata(token0).name(), " and ", IERC20Metadata(token1).name(), " UniswapV2Pair"),
        string.concat(IERC20Metadata(token0).symbol(), "/", IERC20Metadata(token1).symbol(), " UNI-V2")
    ) {
        s_token0 = IERC20(token0);
        s_token1 = IERC20(token1);
    }

    /**
     * @dev returns both reserve value and last time they were updated
     * @return _reserve0 is the amount of token0 that are in first reserve(s_reserve0)
     * @return _reserve1 is the amount of token1 that are in second reserve(s_reserve1)
     * @return _lastTimestamp is last timestamp where s_reserve0 and s_resevrve1 updated
     */
    function getReserves() public view returns(uint112 _reserve0, uint112 _reserve1, uint48 _lastTimestamp) {
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