// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from '@valantis-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import { IERC20 } from '@valantis-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@valantis-core/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';

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
    using SafeERC20 for IERC20;

    /************************************************
     *  CUSTOM ERRORS
     ***********************************************/

    error GaslessSwapEntrypoint__onlyWhitelistedExecutor();
    error GaslessSwapEntrypoint__claimTokens_invalidRecipient();
    error GaslessSwapEntrypoint__claimTokens_invalidToken();
    error GaslessSwapEntrypoint__claimTokens_invalidTokensLength();
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
        @notice Execute batches of swaps with token and/or permit2 signature based approvals.
        @dev Only callable by a whitelisted executor.
        @param _gaslessSwapParams Parameters for ValantisSwapRouter::gaslessSwap.
        @param _ownerSignature Parameters for ValantisSwapRouter::gaslessSwap.
        @param _fee Parameters for Valantis SwapRouter::gaslessSwap.
        @param _tokenPermitInfo Parameters for token's permit approval, if supported.
        @param _permit2Info Parameters for Permit2's approval to ValantisSwapRouter.
        @return amountOut Amounts of output token sent to each recipient.
     */
    function execute(
        GaslessSwapParams[] calldata _gaslessSwapParams,
        bytes[] calldata _ownerSignature,
        uint128[] calldata _fee,
        TokenPermitInfo[] calldata _tokenPermitInfo,
        Permit2Info[] calldata _permit2Info
    ) external override onlyWhitelistedExecutor returns (uint256[] memory amountOut) {
        // It is assumed that all arrays have the same length, otherwise this call reverts
        amountOut = new uint256[](_gaslessSwapParams.length);

        for (uint256 i; i < _gaslessSwapParams.length; i++) {
            if (_tokenPermitInfo[i].isEnabled) {
                _handleTokenPermit(
                    _tokenPermitInfo[i],
                    _gaslessSwapParams[i].intent.owner,
                    _gaslessSwapParams[i].intent.tokenIn,
                    _gaslessSwapParams[i].intent.deadline
                );
            }

            if (_permit2Info[i].isEnabled) {
                _handlePermit2(_permit2Info[i], _gaslessSwapParams[i].intent.owner);
            }

            amountOut[i] = _swapRouter.gaslessSwap(_gaslessSwapParams[i], _ownerSignature[i], _fee[i]);
        }
    }

    /**
        @notice Claims token fees accumulated in this contract.
        @dev By design of SwapRouter::gaslessSwap, fees are transferred into this contract.
        @dev Only callable by `owner`.
        @param _tokens Addresses of tokens to claim.
        @param _recipient The address of the recipient.
     */
    function claimTokens(address[] calldata _tokens, address _recipient) external onlyOwner {
        if (_tokens.length == 0) {
            revert GaslessSwapEntrypoint__claimTokens_invalidTokensLength();
        }

        if (_recipient == address(0)) {
            revert GaslessSwapEntrypoint__claimTokens_invalidRecipient();
        }

        for (uint256 i; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);

            if (address(token) == address(0)) {
                revert GaslessSwapEntrypoint__claimTokens_invalidToken();
            }

            uint256 balance = token.balanceOf(address(this));

            if (balance > 0) {
                token.safeTransfer(_recipient, balance);

                emit TokenClaimed(address(token), _recipient, balance);
            }
        }
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
        if (permit2Info.permitBatch.spender != address(_swapRouter))
            revert GaslessSwapEntrypoint___handlePermit2_unauthorizedSpender();

        _permit2.permit(owner, permit2Info.permitBatch, permit2Info.signature);
    }
}
