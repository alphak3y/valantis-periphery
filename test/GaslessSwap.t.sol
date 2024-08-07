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

    function setUp() public {
        harness = new GaslessSwapHarness();
    }

    function test_checkGaslessSwapParams_reverts() public {

        GaslessSwapParams memory params; 

        vm.expectRevert(GaslessSwap.GaslessSwap__checkGaslessSwapParams_invalidDeadline.selector);

        harness.checkGaslessSwapParams(params);

        params.intent.deadline = block.timestamp + 1;

        vm.expectRevert(GaslessSwap.GaslessSwap__checkGaslessSwapParams_invalidArrayLength.selector);

        harness.checkGaslessSwapParams(params);

        params.isUniversalPool = new bool[](3);

        vm.expectRevert(GaslessSwap.GaslessSwap__checkGaslessSwapParams_arrayLengthMismatch.selector);
        
        harness.checkGaslessSwapParams(params); 
        
        params.pools = new address[](3);
        params.amountInSpecified = new uint256[](3);
        params.payloads = new bytes[](3);

        params.intent.amountIn = 1;

        vm.expectRevert(GaslessSwap.GaslessSwap__checkGaslessSwapParams_invalidAmountInSpecifiedArray.selector);

        harness.checkGaslessSwapParams(params); 

        params.intent.amountIn = 0;

        params.intent.authorizedSender = makeAddr("SENDER");

        vm.expectRevert(GaslessSwap.GaslessSwap__checkGaslessSwapParams_senderNotAuthorized.selector);

        harness.checkGaslessSwapParams(params); 

        params.intent.authorizedSender = address(this);

        harness.checkGaslessSwapParams(params); 


    }


}