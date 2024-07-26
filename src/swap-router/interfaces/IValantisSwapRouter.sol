// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {
    ISovereignPoolSwapCallback
} from '../../../lib/valantis-core/src/pools/interfaces/ISovereignPoolSwapCallback.sol';
import {
    IUniversalPoolSwapCallback
} from '../../../lib/valantis-core/src/pools/interfaces/IUniversalPoolSwapCallback.sol';

import { GaslessSwapParams, DirectSwapParams } from '../structs/ValantisSwapRouterStructs.sol';

interface IValantisSwapRouter is ISovereignPoolSwapCallback, IUniversalPoolSwapCallback {
    // solhint-disable-next-line func-name-mixedcase
    function WETH9() external view returns (address);

    function nonceBitmap(address _signer, uint256 _wordPosition) external view returns (uint256);

    function isLocked() external view returns (bool);

    function allowedUniversalPool() external view returns (address);

    function allowedSovereignPool() external view returns (address);

    function permit2() external view returns (address);

    function protocolFactory() external view returns (address);

    function gaslessSwap(
        GaslessSwapParams calldata _gaslessSwapParams,
        bytes calldata _ownerSignature,
        uint128 _fee
    ) external returns (uint256 amountOut);

    function batchGaslessSwaps(
        GaslessSwapParams[] calldata _gaslessSwapParamsArray,
        bytes[] calldata _ownerSignaturesArray,
        uint128[] calldata _feeArray
    ) external returns (uint256[] memory amountOutArray);

    function swap(DirectSwapParams calldata _directSwapParams) external payable returns (uint256 amountOut);
}
