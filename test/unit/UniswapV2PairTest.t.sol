// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {UniswapV2Pair} from "../../src/core/UniswapV2Pair.sol";
import {DeployUniswapV2Pair} from "../../script/DeployUniswapV2Pair.s.sol";
import {MockUSDT} from "../mocks/MockUSDT.sol";
import {MockWETH} from "../mocks/MockWETH.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract SwapperContract {
    using SafeERC20 for IERC20;
    
    function uniswapV2Callback(address /*sender*/, uint256 /*amount0Out*/, uint256 /*amount1Out*/, bytes calldata data) external {
        (address pairAddress, address token, uint256 amountIn) = abi.decode(data, (address, address, uint256));
        IERC20(token).safeTransfer(pairAddress, amountIn);
    }
}

contract UniswapV2PairTest is Test {
    using SafeERC20 for IERC20;

    DeployUniswapV2Pair deployer;
    UniswapV2Pair pair;

    MockUSDT mockUSDT;
    MockWETH mockWETH;

    address lp_1 = makeAddr("lp_1");
    address lp_2 = makeAddr("lp_2");
    address lp_3 = makeAddr("lp_3");
    address lp_4 = makeAddr("lp_4");

    address swapper1 = makeAddr("swapper1");
    address swapper2 = makeAddr("swapper2");
    address swapper3 = makeAddr("swapper3");
    address swapper4 = makeAddr("swapper4");

    address swapperContractAddress;

    uint256 public LP_INITIAL_USDT_AMOUNT = 1000e6;
    uint256 public LP_INITIAL_WETH_AMOUNT = 100e18;

    event Swap(
        address indexed sender,
        address indexed to,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    );

    function setUp() public {
        mockUSDT = new MockUSDT();
        mockWETH = new MockWETH();

        swapperContractAddress = address(new SwapperContract());

        mockUSDT.mint(lp_1, LP_INITIAL_USDT_AMOUNT);

        mockUSDT.mint(swapper1, 120e6);
        mockUSDT.mint(swapperContractAddress, 120e6);
        

        vm.deal(lp_1, 100 ether);
        vm.prank(lp_1);
        mockWETH.mint{value: 100 ether}();

        vm.deal(swapper1, 20 ether);
        vm.prank(swapper1);
        mockWETH.mint{value: 20 ether}();

        vm.deal(swapperContractAddress, 20 ether);
        vm.prank(swapperContractAddress);
        mockWETH.mint{value: 20 ether}();

        deployer = new DeployUniswapV2Pair();
        pair = UniswapV2Pair(deployer.run(address(mockWETH), address(mockUSDT)));
    }

    function test_MockUSDTDecimals() public view {
        assert(mockUSDT.decimals() == 6);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////// INITIALIZATION /////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

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
        (uint256 reserve0Amount, uint256 reserve1Amount, uint48 lastTimestamp) = pair.getReserves();

        console2.log("First reserve amount:", reserve0Amount);
        console2.log("Second reserve amount:", reserve1Amount);
        console2.log("Last update timestamp:", lastTimestamp);

        assertEq(reserve0Amount, 0);
        assertEq(reserve1Amount, 0);
        assertEq(lastTimestamp, 0);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////// SWAP //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    function test_SwapRevertIfBothAmountOutIsZero() public {
        uint256 amount0Out = 0;
        uint256 amount1Out = 0;

        vm.expectRevert(UniswapV2Pair.UniswapV2Pair__InsufficientOutput.selector);
        pair.swap(amount0Out, amount1Out, swapper1, bytes(""));
    }

    function test_SwapRevertIfBothAmountOutIsGreaterThanZero() public {
        uint256 amount0Out = 10;
        uint256 amount1Out = 100;

        vm.expectRevert(UniswapV2Pair.UniswapV2Pair__CanNotOutputTwoTokens.selector);
        pair.swap(amount0Out, amount1Out, swapper1, bytes(""));
    }

    modifier setReserve {
        vm.startPrank(lp_1);
        mockWETH.approve(address(pair), type(uint256).max);
        mockUSDT.approve(address(pair), type(uint256).max);
        pair.setReserve(100e18, 1000e6);
        vm.stopPrank();
        _;
    }

    function test_SwapToken0OutWork() public setReserve {
        uint256 swapper1WethBalanceBefore = mockWETH.balanceOf(swapper1);
        uint256 swapper1UsdtBalanceBefore = mockUSDT.balanceOf(swapper1);

        uint256 pairWethBalanceBefore = mockWETH.balanceOf(address(pair));
        uint256 pairUsdtBalanceBefore = mockUSDT.balanceOf(address(pair));

        uint256 mwethOut = 10e18;
        uint256 musdtInWithFee = 112e6;
        vm.prank(swapper1);
        mockUSDT.transfer(address(pair), musdtInWithFee);
        vm.expectEmit();
        emit Swap(swapper1, swapper1, 0, musdtInWithFee, mwethOut, 0);
        vm.prank(swapper1);
        pair.swap(mwethOut, 0, swapper1, bytes(""));

        uint256 swapper1WethBalanceAfter = mockWETH.balanceOf(swapper1);
        uint256 swapper1UsdtBalanceAfter = mockUSDT.balanceOf(swapper1);

        uint256 pairWethBalanceAfter = mockWETH.balanceOf(address(pair));
        uint256 pairUsdtBalanceAfter = mockUSDT.balanceOf(address(pair));

        assert(swapper1WethBalanceAfter == swapper1WethBalanceBefore + mwethOut);
        assert(swapper1UsdtBalanceBefore - musdtInWithFee == swapper1UsdtBalanceAfter);

        assert(pairWethBalanceBefore - mwethOut == pairWethBalanceAfter);
        assert(pairUsdtBalanceAfter == pairUsdtBalanceBefore + musdtInWithFee);
    }

    function test_SwapToken0OutSwaperContractWork() public setReserve {
        uint256 swapper1WethBalanceBefore = mockWETH.balanceOf(swapper1);
        uint256 swapperContractUsdtBalanceBefore = mockUSDT.balanceOf(swapperContractAddress);

        uint256 pairWethBalanceBefore = mockWETH.balanceOf(address(pair));
        uint256 pairUsdtBalanceBefore = mockUSDT.balanceOf(address(pair));

        uint256 mwethOut = 10e18;
        uint256 musdtInWithFee = 112e6;
        bytes memory data = abi.encode(address(pair), address(mockUSDT), musdtInWithFee);

        vm.expectEmit();
        emit Swap(swapperContractAddress, swapper1, 0, musdtInWithFee, mwethOut, 0);
        vm.prank(swapperContractAddress);
        pair.swap(mwethOut, 0, swapper1, data);

        uint256 swapper1WethBalanceAfter = mockWETH.balanceOf(swapper1);
        uint256 swapperContractUsdtBalanceAfter = mockUSDT.balanceOf(swapperContractAddress);

        uint256 pairWethBalanceAfter = mockWETH.balanceOf(address(pair));
        uint256 pairUsdtBalanceAfter = mockUSDT.balanceOf(address(pair));

        assert(swapper1WethBalanceAfter == swapper1WethBalanceBefore + mwethOut);
        assert(swapperContractUsdtBalanceBefore - musdtInWithFee == swapperContractUsdtBalanceAfter);

        assert(pairWethBalanceBefore - mwethOut == pairWethBalanceAfter);
        assert(pairUsdtBalanceAfter == pairUsdtBalanceBefore + musdtInWithFee);
    }

    function test_SwapToken0OutFailIfKNotFulfilled() public setReserve {
        uint256 mwethOut = 10e18;
        uint256 musdtInWithFee = 111e6;
        vm.prank(swapper1);
        mockUSDT.transfer(address(pair), musdtInWithFee);
        vm.expectRevert(UniswapV2Pair.UniswapV2Pair__K.selector);
        pair.swap(mwethOut, 0, swapper1, bytes(""));
    }

    function test_SwapToken1OutWork() public setReserve {
        uint256 swapper1WethBalanceBefore = mockWETH.balanceOf(swapper1);
        uint256 swapper1UsdtBalanceBefore = mockUSDT.balanceOf(swapper1);

        uint256 pairWethBalanceBefore = mockWETH.balanceOf(address(pair));
        uint256 pairUsdtBalanceBefore = mockUSDT.balanceOf(address(pair));

        uint256 mwethInWithFee = 12e18;
        uint256 musdtOut = 100e6;
        vm.prank(swapper1);
        mockWETH.transfer(address(pair), mwethInWithFee);
        vm.expectEmit();
        emit Swap(swapper1, swapper1, mwethInWithFee, 0, 0, musdtOut);
        vm.prank(swapper1);
        pair.swap(0, musdtOut, swapper1, bytes(""));

        uint256 swapper1WethBalanceAfter = mockWETH.balanceOf(swapper1);
        uint256 swapper1UsdtBalanceAfter = mockUSDT.balanceOf(swapper1);

        uint256 pairWethBalanceAfter = mockWETH.balanceOf(address(pair));
        uint256 pairUsdtBalanceAfter = mockUSDT.balanceOf(address(pair));

        assert(swapper1WethBalanceBefore - mwethInWithFee == swapper1WethBalanceAfter);
        assert(swapper1UsdtBalanceAfter == swapper1UsdtBalanceBefore + musdtOut);

        assert(pairWethBalanceAfter == pairWethBalanceBefore + mwethInWithFee);
        assert(pairUsdtBalanceBefore - musdtOut == pairUsdtBalanceAfter);
    }

    function test_SwapToken1OutSwaperContractWork() public setReserve {
        uint256 swapperContractWethBalanceBefore = mockWETH.balanceOf(swapperContractAddress);
        uint256 swapper1UsdtBalanceBefore = mockUSDT.balanceOf(swapper1);

        uint256 pairWethBalanceBefore = mockWETH.balanceOf(address(pair));
        uint256 pairUsdtBalanceBefore = mockUSDT.balanceOf(address(pair));

        uint256 mwethInWithFee = 12e18;
        uint256 musdtOut = 100e6;

        bytes memory data = abi.encode(address(pair), address(mockWETH), mwethInWithFee);

        vm.expectEmit();
        emit Swap(swapperContractAddress, swapper1, mwethInWithFee, 0, 0, musdtOut);

        vm.prank(swapperContractAddress);
        pair.swap(0, musdtOut, swapper1, data);

        uint256 swapperContractWethBalanceAfter = mockWETH.balanceOf(swapperContractAddress);
        uint256 swapper1UsdtBalanceAfter = mockUSDT.balanceOf(swapper1);

        uint256 pairWethBalanceAfter = mockWETH.balanceOf(address(pair));
        uint256 pairUsdtBalanceAfter = mockUSDT.balanceOf(address(pair));

        assert(swapperContractWethBalanceBefore - mwethInWithFee == swapperContractWethBalanceAfter);
        assert(swapper1UsdtBalanceAfter == swapper1UsdtBalanceBefore + musdtOut);

        assert(pairWethBalanceAfter == pairWethBalanceBefore + mwethInWithFee);
        assert(pairUsdtBalanceBefore - musdtOut == pairUsdtBalanceAfter);
    }

    function test_SwapToken1OutFailIfKNotFulfilled() public setReserve {
        uint256 mwethInWithFee = 11e18;
        uint256 musdtOut = 100e6;
        vm.prank(swapper1);
        mockWETH.transfer(address(pair), mwethInWithFee);
        vm.expectRevert(UniswapV2Pair.UniswapV2Pair__K.selector);
        vm.prank(swapper1);
        pair.swap(0, musdtOut, swapper1, bytes(""));
    }
}