//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { BaseDeploy } from "test/utils/BaseDeploy.sol";
import { Test, console2 } from "forge-std/Test.sol";
import { UniswapV3Pool } from "contracts/v3-core/UniswapV3Pool.sol";
import { SwapRouter } from "contracts/v3-periphery/SwapRouter.sol";
import { TransferHelper } from "contracts/v3-periphery/libraries/TransferHelper.sol";
import { NonfungiblePositionManager } from "contracts/v3-periphery/NonfungiblePositionManager.sol";
import { NonfungibleTokenPositionDescriptor } from "contracts/v3-periphery/NonfungibleTokenPositionDescriptor.sol";
import { IPoolInitializer } from "contracts/v3-periphery/interfaces/IPoolInitializer.sol";
import { INonfungiblePositionManager } from "contracts/v3-periphery/interfaces/INonfungiblePositionManager.sol";

import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
import { encodePriceSqrt } from "test/utils/Math.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/v3-periphery/test/TestERC20.sol";
import "forge-std/StdUtils.sol";
import 'test/utils/TickHelper.sol';
contract v3InteractiveTest is BaseDeploy {
    function setUp() public override {
        super.setUp();
    }
    function test_POOL_INIT_CODE_HASH() public {
        bytes32 POOL_INIT_CODE_HASH = keccak256(abi.encodePacked(type(UniswapV3Pool).creationCode));
        console2.log("POOL_INIT_CODE_HASH"); 
        console2.logBytes32(POOL_INIT_CODE_HASH);
    }
    function test_V3Interactive() public {
        vm.startPrank(user);
        getToken();
		mintNewPool(tokens[1], tokens[2], FEE_LOW, INIT_PRICE);
        IERC20(tokens[1]).transfer(
			address(swapRouter),
			type(uint256).max / 5
		);
		IERC20(tokens[2]).transfer(
			address(swapRouter),
			type(uint256).max / 5
		);
		mintNewPosition(tokens[1], tokens[2],FEE_LOW,getMinTick(TICK_LOW),getMaxTick(TICK_LOW),1000 * 10 ** 18,1000 * 10 ** 18);
		vm.stopPrank();
    }

    function getToken() internal {
		for (uint256 i = 0; i < tokenNumber; i++) {
			address token = address(new TestERC20(type(uint256).max / 2));
			tokens.push(token);
			TransferHelper.safeApprove(
				token,
				address(nonfungiblePositionManager),
				type(uint256).max / 2
			);
			TransferHelper.safeApprove(
				token,
				address(swapRouter),
				type(uint256).max / 2
			);
		}
	}

    function mintNewPool(
		address token0,
		address token1,
		uint24 fee,
		uint160 currentPrice
	) internal virtual returns (address) {
		(token0, token1) = token0 < token1 ? (token0, token1) : (token1, token0);
		/* 创建池子 */
		return
			nonfungiblePositionManager.createAndInitializePoolIfNecessary(
				token0,
				token1,
				fee,
				currentPrice
			);
	}

	function mintNewPosition(
		address token0,
		address token1,
		uint24 fee,
		int24 tickLower,
		int24 tickUpper,
		uint256 amount0ToMint,
		uint256 amount1ToMint
	)
		internal
		virtual
		returns (
			uint256 tokenId,
			uint128 liquidity,
			uint256 amount0,
			uint256 amount1
		)
	{
		(token0, token1) = token0 < token1 ? (token0, token1) : (token1, token0);
		INonfungiblePositionManager.MintParams
			memory liquidityParams = INonfungiblePositionManager.MintParams({
				token0: token0,
				token1: token1,
				fee: fee,
				tickLower: tickLower,
				tickUpper: tickUpper,
				recipient: deployer,
				amount0Desired: amount0ToMint,
				amount1Desired: amount1ToMint,
				amount0Min: 0,
				amount1Min: 0,
				deadline: 1
			});

		nonfungiblePositionManager.mint(liquidityParams);
	}
}