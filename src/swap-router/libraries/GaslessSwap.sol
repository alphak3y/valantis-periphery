// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { GaslessSwapParams } from '../structs/ValantisSwapRouterStructs.sol';

library GaslessSwap {
    error GaslessSwap__checkGaslessSwapParams_arrayLengthMismatch();
    error GaslessSwap__checkGaslessSwapParams_equalTokenInAndTokenOut();
    error GaslessSwap__checkGaslessSwapParams_invalidAmountInSpecifiedArray();
    error GaslessSwap__checkGaslessSwapParams_invalidArrayLength();
    error GaslessSwap__checkGaslessSwapParams_invalidDeadline();
    error GaslessSwap__checkGaslessSwapParams_senderNotAuthorized();

    function checkGaslessSwapParams(GaslessSwapParams calldata gaslessSwapParams) internal view {
        if (block.timestamp > gaslessSwapParams.intent.deadline)
            revert GaslessSwap__checkGaslessSwapParams_invalidDeadline();

        if (gaslessSwapParams.isUniversalPool.length == 0) {
            revert GaslessSwap__checkGaslessSwapParams_invalidArrayLength();
        }

        if (
            gaslessSwapParams.isUniversalPool.length != gaslessSwapParams.pools.length ||
            gaslessSwapParams.pools.length != gaslessSwapParams.amountInSpecified.length ||
            gaslessSwapParams.amountInSpecified.length != gaslessSwapParams.payloads.length
        ) revert GaslessSwap__checkGaslessSwapParams_arrayLengthMismatch();

        // tokenIn and tokenOut cannot be the same
        if (gaslessSwapParams.intent.tokenIn == gaslessSwapParams.intent.tokenOut)
            revert GaslessSwap__checkGaslessSwapParams_equalTokenInAndTokenOut();

        uint256 amountInSpecifiedSum;
        uint256 numTokenInSwaps = gaslessSwapParams.amountInSpecified.length;
        for (uint256 i; i < numTokenInSwaps; ) {
            amountInSpecifiedSum += gaslessSwapParams.amountInSpecified[i];

            unchecked {
                ++i;
            }
        }

        // Total sum of amount specified array must match amountIn
        if (amountInSpecifiedSum != gaslessSwapParams.intent.amountIn) {
            revert GaslessSwap__checkGaslessSwapParams_invalidAmountInSpecifiedArray();
        }

        // Enforce that caller is authorizedSender
        if (msg.sender != gaslessSwapParams.intent.authorizedSender)
            revert GaslessSwap__checkGaslessSwapParams_senderNotAuthorized();
    }
}
