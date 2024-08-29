// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { DirectSwapParams } from '../structs/ValantisSwapRouterStructs.sol';

library DirectSwap {
    error DirectSwap__checkDirectSwapParams_arrayLengthMismatch();
    error DirectSwap__checkDirectSwapParams_equalTokenInAndTokenOut();
    error DirectSwap__checkDirectSwapParams_incorrectNativeTokenAmountIn();
    error DirectSwap__checkDirectSwapParams_invalidArrayLength();
    error DirectSwap__checkDirectSwapParams_invalidDeadline();

    function checkDirectSwapParams(DirectSwapParams calldata directSwapParams, uint256 msgValue) internal view {
        if (block.timestamp > directSwapParams.deadline) revert DirectSwap__checkDirectSwapParams_invalidDeadline();

        if (directSwapParams.isUniversalPool.length == 0) {
            revert DirectSwap__checkDirectSwapParams_invalidArrayLength();
        }

        if (
            directSwapParams.isUniversalPool.length != directSwapParams.pools.length ||
            directSwapParams.pools.length != directSwapParams.amountInSpecified.length ||
            directSwapParams.amountInSpecified.length != directSwapParams.payloads.length
        ) revert DirectSwap__checkDirectSwapParams_arrayLengthMismatch();

        // tokenIn and tokenOut cannot be the same
        if (directSwapParams.tokenIn == directSwapParams.tokenOut)
            revert DirectSwap__checkDirectSwapParams_equalTokenInAndTokenOut();

        // In case tokenIn is ETH, we require that msg.value is equal to total amountIn specified
        if (msgValue > 0) {
            uint256 amountInTotal;
            for (uint256 i; i < directSwapParams.amountInSpecified.length; ) {
                amountInTotal += directSwapParams.amountInSpecified[i];

                unchecked {
                    ++i;
                }
            }

            if (amountInTotal != msgValue) {
                revert DirectSwap__checkDirectSwapParams_incorrectNativeTokenAmountIn();
            }
        }
    }
}
