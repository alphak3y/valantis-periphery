// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { GaslessSwapParams } from '../structs/ValantisSwapRouterStructs.sol';
import { TokenPermitInfo } from '../structs/GaslessSwapEntrypointStructs.sol';
import { Permit2Info } from '../structs/GaslessSwapEntrypointStructs.sol';

interface IGaslessSwapEntrypoint {
    event TokenClaimed(address token, address recipient, uint256 balance);

    // solhint-disable-next-line func-name-mixedcase
    function DAI() external view returns (address);

    function swapRouter() external view returns (address);

    function permit2() external view returns (address);

    function isWhitelistedExecutor(address _executor) external view returns (bool);

    function whitelistExecutor(address _executor) external;

    function removeExecutor(address _executor) external;

    function execute(
        GaslessSwapParams[] calldata _gaslessSwapParams,
        bytes[] calldata _ownerSignature,
        uint128[] calldata _fee,
        TokenPermitInfo[] calldata _tokenPermitInfo,
        Permit2Info[] calldata _permit2Info
    ) external returns (uint256[] memory amountOut);
}
