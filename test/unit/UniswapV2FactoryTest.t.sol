// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {DeployUniswapV2Factory} from "../../script/DeployUniswapV2Factory.s.sol";
import {MockUSDT} from "../mocks/MockUSDT.sol";
import {MockWETH} from "../mocks/MockWETH.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UniswapV2Factory} from "src/contracts/core/UniswapV2Factory.sol";

contract UniswapV2PairTest is Test {
    using SafeERC20 for IERC20;

    DeployUniswapV2Factory deployer;

    
    UniswapV2Factory factory;

    MockWETH mockWETH;
    MockUSDT mockUSDT;
    

    address lp_1 = makeAddr("lp_1");
    address lp_2 = makeAddr("lp_2");
    address lp_3 = makeAddr("lp_3");
    address lp_4 = makeAddr("lp_4");

    address swapper1 = makeAddr("swapper1");
    address swapper2 = makeAddr("swapper2");
    address swapper3 = makeAddr("swapper3");
    address swapper4 = makeAddr("swapper4");

    address swapperContractAddress;

    address feeReceiver = makeAddr("fee taker");
    address newAdmin = makeAddr("new admin");

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
        mockWETH = new MockWETH();
        mockUSDT = new MockUSDT();

        deployer = new DeployUniswapV2Factory();
        factory = UniswapV2Factory(deployer.run());
        console2.log("true:", address(mockWETH) < address(mockUSDT));
        
    }

    function test_CreatePair() public {
        // event test
        address pair = factory.createPair(address(mockWETH), address(mockUSDT));

        address recordedPair = factory.getPair(address(mockWETH), address(mockUSDT));
        
        address recordedPairByIndex = factory.pairByIndex(0);

        uint256 createdPairsNumber = factory.allPairLength();

        assert(pair == recordedPair);
        assert(pair == recordedPairByIndex);
        assert(createdPairsNumber == 1);
    }

    function test_CreatePairFailIfSameTokens() public {
        vm.expectRevert(UniswapV2Factory.UniswapV2Factory__IdenticalAddress.selector);
        factory.createPair(address(mockWETH), address(mockWETH));
    }

    function test_CreatePairFailIfZeroAddress() public {
        vm.expectRevert(UniswapV2Factory.UniswapV2Factory__ZeroAddress.selector);
        factory.createPair(address(mockWETH), address(0));

        vm.expectRevert(UniswapV2Factory.UniswapV2Factory__ZeroAddress.selector);
        factory.createPair(address(0), address(mockUSDT));
    }

    function test_CreatePairFailWhenCreateAgainSameTokenPair() public {
        // event test
        factory.createPair(address(mockWETH), address(mockUSDT));

        vm.expectRevert(UniswapV2Factory.UniswapV2Factory__PairAlreadyExist.selector);
        factory.createPair(address(mockWETH), address(mockUSDT));
    }

    function test_setFeeTo() public {
        vm.prank(factory.getAdmin());
        factory.setFeeTo(feeReceiver);
    }

    function test_setFeeToInfNoAdmin() public {
        vm.expectRevert(UniswapV2Factory.UniswapV2Factory__NotAdmin.selector);
        vm.prank(lp_2);
        factory.setFeeTo(feeReceiver);
    }

    function test_setAdmin() public {
        vm.prank(factory.getAdmin());
        factory.setAdmin(newAdmin);
    }

    function test_setAdminFairIfNoAdmin() public {
        vm.expectRevert(UniswapV2Factory.UniswapV2Factory__NotAdmin.selector);
        vm.prank(lp_1);
        factory.setAdmin(newAdmin);
    }
}