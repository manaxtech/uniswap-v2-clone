// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {UniswapV2Pair} from "../../src/core/UniswapV2Pair.sol";
import {DeployUniswapV2Pair} from "../../script/DeployUniswapV2Pair.s.sol";
import {MockUSDT} from "../mocks/MockUSDT.sol";
import {MockWETH} from "../mocks/MockWETH.sol";

contract UniswapV2PairTest is Test {
    DeployUniswapV2Pair deployer;
    UniswapV2Pair pair;

    MockUSDT mockUSDT;
    MockWETH mockWETH;

    address lp_provider1 = makeAddr("lp_provider1");
    address lp_provider2 = makeAddr("lp_provider2");
    address lp_provider3 = makeAddr("lp_provider3");
    address lp_provider4 = makeAddr("lp_provider4");

    address swapper1 = makeAddr("swapper1");
    address swapper2 = makeAddr("swapper2");
    address swapper3 = makeAddr("swapper3");
    address swapper4 = makeAddr("swapper4");

    uint256 public LP_INITIAL_USDT_AMOUNT = 1_000e6;
    uint256 public LP_INITIAL_WETH_AMOUNT = 100e18;

    function setUp() public {
        mockUSDT = new MockUSDT();
        mockWETH = new MockWETH();

        mockUSDT.mint(lp_provider1, LP_INITIAL_USDT_AMOUNT);
        

        vm.deal(lp_provider1, 100 ether);
        mockWETH.mint{value: 100 ether}();

        deployer = new DeployUniswapV2Pair();
        pair = UniswapV2Pair(deployer.run(address(mockWETH), address(mockUSDT)));
    }

    function test_MockUSDTDecimals() public view {
        assert(mockUSDT.decimals() == 6);
    }

    function test_NameAndSymbol() public view {
        string memory pairName = pair.name();
        string memory pairSymbol = pair.symbol();

        string memory expectedName = "MockWETH and MockUSDT UniswapV2Pair";
        string memory expectedSymbol = "MWETH/MUSDT UNI-V2";

        console2.log("Pair Name:", pairName);
        console2.log("Pair symbol:", pairSymbol);

        assertEq(keccak256(abi.encodePacked(pairName)), keccak256(abi.encodePacked(expectedName)));
        assertEq(keccak256(abi.encodePacked(pairSymbol)), keccak256(abi.encodePacked(expectedSymbol)));
    }

    function test_GetToken() public view {
        (address firstToken, address secondToken) = pair.getTokens();

        console2.log("First token:", firstToken);
        console2.log("Second token:", secondToken);

        assertEq(firstToken, address(mockWETH));
        assertEq(secondToken, address(mockUSDT));
    }

    function test_GetReserve() public view {
        (uint112 reserve0Amount, uint112 reserve1Amount, uint48 lastTimestamp) = pair.getReserves();

        console2.log("First reserve amount:", reserve0Amount);
        console2.log("Second reserve amount:", reserve1Amount);
        console2.log("Last update timestamp:", lastTimestamp);

        assertEq(reserve0Amount, 0);
        assertEq(reserve1Amount, 0);
        assertEq(lastTimestamp, 0);
    }
}