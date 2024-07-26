// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { GaslessSwapIntent } from '../structs/ValantisSwapRouterStructs.sol';

library GaslessSwapIntentHash {
    bytes32 public constant GASLESS_SWAP_INTENT_TYPEHASH =
        keccak256(
            // solhint-disable-next-line max-line-length
            'GaslessSwapIntent(address tokenIn,address tokenOut,address owner,address recipient,address authorizedSender,address feeToken,uint256 amountIn,uint256 amountOutMin,uint128 maxFee,uint256 nonce,uint256 deadline)'
        );

    function hashStruct(GaslessSwapIntent calldata swapIntent) internal pure returns (bytes32) {
        return keccak256(abi.encode(GASLESS_SWAP_INTENT_TYPEHASH, swapIntent));
    }
}
