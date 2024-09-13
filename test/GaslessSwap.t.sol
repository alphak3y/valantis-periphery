// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';

import { GaslessSwap } from 'src/swap-router/libraries/GaslessSwap.sol';
import { GaslessSwapParams } from 'src/swap-router/structs/ValantisSwapRouterStructs.sol';

contract GaslessSwapHarness {
    function checkGaslessSwapParams(GaslessSwapParams calldata gaslessSwapParams) external view {
        GaslessSwap.checkGaslessSwapParams(gaslessSwapParams);
    }
}

contract GaslessSwapParamsTest is Test {
    GaslessSwapHarness harness;

    address public MOCK_TOKEN_IN = address(0x123);
    address public MOCK_TOKEN_OUT = address(0x456);

    function setUp() public {
        harness = new GaslessSwapHarness();
    }

    function test_checkGaslessSwapParams_reverts() public {
        GaslessSwapParams memory params;

        params.intent.tokenIn = MOCK_TOKEN_IN;
        params.intent.tokenOut = MOCK_TOKEN_OUT;

        vm.expectRevert(GaslessSwap.GaslessSwap__checkGaslessSwapParams_invalidDeadline.selector);
        harness.checkGaslessSwapParams(params);

        params.intent.deadline = block.timestamp + 1;

        vm.expectRevert(GaslessSwap.GaslessSwap__checkGaslessSwapParams_invalidArrayLength.selector);
        harness.checkGaslessSwapParams(params);

        params.isUniversalPool = new bool[](3);

        vm.expectRevert(GaslessSwap.GaslessSwap__checkGaslessSwapParams_invalidFeeRecipient.selector);
        harness.checkGaslessSwapParams(params);

        params.feeRecipient = address(0x789);

        vm.expectRevert(GaslessSwap.GaslessSwap__checkGaslessSwapParams_arrayLengthMismatch.selector);
        harness.checkGaslessSwapParams(params);

        params.pools = new address[](3);
        params.amountInSpecified = new uint256[](3);
        params.payloads = new bytes[](3);
        params.intent.tokenOut = MOCK_TOKEN_IN;

        vm.expectRevert(GaslessSwap.GaslessSwap__checkGaslessSwapParams_equalTokenInAndTokenOut.selector);
        harness.checkGaslessSwapParams(params);

        params.intent.tokenOut = MOCK_TOKEN_OUT;
        params.intent.amountIn = 1;

        vm.expectRevert(GaslessSwap.GaslessSwap__checkGaslessSwapParams_invalidAmountInSpecifiedArray.selector);
        harness.checkGaslessSwapParams(params);

        params.intent.amountIn = 0;
        params.intent.authorizedSender = makeAddr('SENDER');

        vm.expectRevert(GaslessSwap.GaslessSwap__checkGaslessSwapParams_senderNotAuthorized.selector);
        harness.checkGaslessSwapParams(params);

        params.intent.authorizedSender = address(this);

        harness.checkGaslessSwapParams(params);
    }
}
