// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./V4.sol";
import "./ExamBase.sol";

// =============================================================================
// TASK 4. Four things to fill in.
// Trades against the pool you filled in Task 3.
//
// This contract also has to be holding your tokens before the swap will work.
// =============================================================================

contract Task4Swap is ExamBase {
    using BalanceDeltaLibrary for BalanceDelta;

    IPoolSwapTest public immutable swapRouter;

    uint256 public predictedAmountOut;
    bool public predictionRecorded;

    event PredictionRecorded(uint256 expectedAmountOut);
    event SwapExecuted(bytes32 poolId, bool zeroForOne, uint256 amountIn, int256 amount0, int256 amount1);

    constructor(
        address _poolManager,
        address _swapRouter,
        address _tokenA,
        address _tokenB,
        uint24 _fee,
        int24 _tickSpacing
    ) ExamBase(_poolManager, _tokenA, _tokenB, _fee, _tickSpacing) {
        swapRouter = IPoolSwapTest(_swapRouter);

        // Provided. Same reason as Task 3: the router moves the tokens, so it needs
        // permission first.
        IERC20(_tokenA).approve(_swapRouter, type(uint256).max);
        IERC20(_tokenB).approve(_swapRouter, type(uint256).max);
    }

    /// @notice Commit to the output you expect, before you find out what it really is.
    function recordPrediction(uint256 expectedAmountOut) external {
        require(!predictionRecorded, "you have already recorded a prediction, it cannot be changed");
        require(expectedAmountOut > 0, "your prediction must be greater than zero");

        // TODO 4.1 --------------------------------------------------------
        predictedAmountOut = expectedAmountOut;
        predictionRecorded = true;
        emit PredictionRecorded(expectedAmountOut);
    }

    /// @notice Swaps an exact amount in.
    function swapExactIn(bool zeroForOne, uint256 amountIn) external returns (int256 amount0, int256 amount1) {
        require(poolExists(), "the pool is not open, run Task 2 first and check your constructor values match");
        require(amountIn > 0, "amountIn must be greater than zero");

        // TODO 4.2 --------------------------------------------------------
        // No swapping until a prediction has been committed.
        require(predictionRecorded, "record your prediction before you swap");

        // TODO 4.3 --------------------------------------------------------
        // A negative amountSpecified means "this is exactly what I am putting in".
        int256 amountSpecified = -int256(amountIn);

        // TODO 4.4 --------------------------------------------------------
        // Selling currency0 pushes the price down, so the limit goes at the bottom
        // of the scale. Selling currency1 pushes it up, so the limit goes at the top.
        uint160 priceLimit = zeroForOne ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1;

        // Provided. This is the call itself.
        BalanceDelta delta = swapRouter.swap(
            poolKey(),
            SwapParams({zeroForOne: zeroForOne, amountSpecified: amountSpecified, sqrtPriceLimitX96: priceLimit}),
            IPoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ""
        );

        // Provided. One of these is negative, the token you paid. The other is
        // positive, the token you received.
        amount0 = delta.amount0();
        amount1 = delta.amount1();
        emit SwapExecuted(poolId(), zeroForOne, amountIn, amount0, amount1);
    }
}
