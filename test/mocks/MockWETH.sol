// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockWETH is ERC20, Ownable {
    constructor() ERC20("MockWETH", "MWETH") Ownable(msg.sender) {}

    function mint() public payable{
        _mint(msg.sender, msg.value);
    }
}