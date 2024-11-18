// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from '@valantis-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol';

import { IAllowanceTransfer } from './interfaces/IAllowanceTransfer.sol';
import { IDaiPermit } from './interfaces/IDaiPermit.sol';
import { IERC2612 } from './interfaces/IERC2612.sol';
import { IGaslessSwapEntrypoint } from './interfaces/IGaslessSwapEntrypoint.sol';
import { IValantisSwapRouter } from './interfaces/IValantisSwapRouter.sol';
import { GaslessSwapParams } from './structs/ValantisSwapRouterStructs.sol';
import { TokenPermitInfo } from './structs/GaslessSwapEntrypointStructs.sol';
import { Permit2Info } from './structs/GaslessSwapEntrypointStructs.sol';

/**
    @title Gasless Swap Entrypoint.
    @notice Contract to bundle token and/or Permit2 approvals
            prior to execution of Gasless Swaps through Valantis Swap Router.
 */
contract GaslessSwapEntrypoint is IGaslessSwapEntrypoint, Ownable {
    /************************************************
     *  CUSTOM ERRORS
     ***********************************************/

    error GaslessSwapEntrypoint__onlyWhitelistedExecutor();
    error GaslessSwapEntrypoint__constructor_invalidDai();
    error GaslessSwapEntrypoint__constructor_invalidSwapRouter();
    error GaslessSwapEntrypoint__execute_onlyWhitelistedExecutor();
    error GaslessSwapEntrypoint__whitelistExecutor_invalidExecutor();
    error GaslessSwapEntrypoint___handlePermit2_unauthorizedSpender();

    /************************************************
     *  IMMUTABLES
     ***********************************************/

    /**
        @notice Address of DAI token.
     */
    address public immutable DAI;

    /**
        @notice Permit2 deployment.
        @dev Determined by `_swapRouter`.
     */
    IAllowanceTransfer private immutable _permit2;

    /**
        @notice Valantis Swap Router deployments.
     */
    IValantisSwapRouter private immutable _swapRouter;

    /************************************************
     *  STORAGE
     ***********************************************/

    /**
        @notice Boolean mapping of whitelisted accounts who can execute swaps.
     */
    mapping(address => bool) private _executorWhitelist;

    /************************************************
     *  CONSTRUCTOR
     ***********************************************/

    constructor(address _owner, address swapRouter_, address _dai) {
        if (swapRouter_ == address(0)) revert GaslessSwapEntrypoint__constructor_invalidSwapRouter();
        if (_dai == address(0)) revert GaslessSwapEntrypoint__constructor_invalidDai();

        _swapRouter = IValantisSwapRouter(swapRouter_);
        _permit2 = IAllowanceTransfer(_swapRouter.permit2());
        DAI = _dai;

        if (_owner != address(0)) transferOwnership(_owner);
    }

    /************************************************
     *  MODIFIERS
     ***********************************************/

    modifier onlyWhitelistedExecutor() {
        if (!_executorWhitelist[msg.sender]) revert GaslessSwapEntrypoint__onlyWhitelistedExecutor();
        _;
    }

    /************************************************
     *  EXTERNAL VIEW FUNCTIONS
     ***********************************************/

    /**
        @notice Address of Valantis Swap Router.
     */
    function swapRouter() external view override returns (address) {
        return address(_swapRouter);
    }

    /**
        @notice Address of Permit2.
     */
    function permit2() external view override returns (address) {
        return address(_permit2);
    }

    /**
        @notice Returns true if `_executor` has been whitelisted, false otherwise.
     */
    function isWhitelistedExecutor(address _executor) external view override returns (bool) {
        return _executorWhitelist[_executor];
    }

    /************************************************
     *  EXTERNAL FUNCTIONS
     ***********************************************/

    /**
        @notice Whitelist account which is able to execute swaps (Executor).
        @param _executor Executor account to whitelist.
        @dev Only callable by `owner`.
     */
    function whitelistExecutor(address _executor) external override onlyOwner {
        if (_executor == address(0)) revert GaslessSwapEntrypoint__whitelistExecutor_invalidExecutor();

        _executorWhitelist[_executor] = true;
    }

    /**
        @notice Remove account to prevent it from executing swaps.
        @param _executor Executor account to remove.
        @dev Only callable by `owner`.
     */
    function removeExecutor(address _executor) external override onlyOwner {
        _executorWhitelist[_executor] = false;
    }

    /**
        @notice Execute a swap with token and/or permit2 signature based approvals.
        @dev Only callable by a whitelisted executor.
        @param _gaslessSwapParams Parameter for ValantisSwapRouter::gaslessSwap.
        @param _ownerSignature Parameter for ValantisSwapRouter::gaslessSwap.
        @param _fee Parameter for Valantis SwapRouter::gaslessSwap.
        @param _tokenPermitInfo Parameters for token's permit approval, if supported.
        @param _permit2Info Parameters for Permit2's approval to ValantisSwapRouter.
        @return amountOut Amount of output token sent to recipient.
     */
    function execute(
        GaslessSwapParams calldata _gaslessSwapParams,
        bytes calldata _ownerSignature,
        uint128 _fee,
        TokenPermitInfo calldata _tokenPermitInfo,
        Permit2Info calldata _permit2Info
    ) external override onlyWhitelistedExecutor returns (uint256 amountOut) {
        _handleTokenPermit(
            _tokenPermitInfo,
            _gaslessSwapParams.intent.owner,
            _gaslessSwapParams.intent.tokenIn,
            _gaslessSwapParams.intent.deadline
        );

        _handlePermit2(_permit2Info, _gaslessSwapParams.intent.owner);

        amountOut = _swapRouter.gaslessSwap(_gaslessSwapParams, _ownerSignature, _fee);
    }

    /************************************************
     *  PRIVATE FUNCTIONS
     ***********************************************/

    function _handleTokenPermit(
        TokenPermitInfo calldata tokenPermitInfo,
        address owner,
        address token,
        uint256 deadline
    ) private {
        // Skip token approval for Permit2
        if (!tokenPermitInfo.isEnabled) return;

        if (token == DAI) {
            (uint256 nonce, uint8 v, uint256 r, uint256 s) = abi.decode(
                tokenPermitInfo.data,
                (uint256, uint8, uint256, uint256)
            );
            IDaiPermit(DAI).permit(owner, address(_permit2), nonce, deadline, true, v, bytes32(r), bytes32(s));
        } else {
            (uint8 v, uint256 r, uint256 s) = abi.decode(tokenPermitInfo.data, (uint8, uint256, uint256));
            IERC2612(token).permit(owner, address(_permit2), type(uint256).max, deadline, v, bytes32(r), bytes32(s));
        }
    }

    function _handlePermit2(Permit2Info calldata permit2Info, address owner) private {
        // Skip Permit2 approval for Swap Router
        if (!permit2Info.isEnabled) return;

        if (permit2Info.permitBatch.spender != address(_swapRouter))
            revert GaslessSwapEntrypoint___handlePermit2_unauthorizedSpender();

        _permit2.permit(owner, permit2Info.permitBatch, permit2Info.signature);
    }
}
