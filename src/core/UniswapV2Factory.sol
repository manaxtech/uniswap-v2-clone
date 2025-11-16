// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";

contract UniswapV2Factory is IUniswapV2Factory {
    address private immutable i_feeTo;

    constructor(address _feeTo) {
        i_feeTo = _feeTo;
    }
    function feeTo() external view returns (address) {
        return i_feeTo;
    }
}