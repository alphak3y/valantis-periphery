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

contract GaslessSwapEntrypoint is IGaslessSwapEntrypoint, Ownable {
    /************************************************
     *  CUSTOM ERRORS
     ***********************************************/

    error GaslessSwapEntrypoint__onlyWhitelistedSolver();
    error GaslessSwapEntrypoint__constructor_invalidDai();
    error GaslessSwapEntrypoint__constructor_invalidSwapRouter();
    error GaslessSwapEntrypoint__execute_onlyWhitelistedSolver();
    error GaslessSwapEntrypoint__whitelistSolver_invalidSolver();
    error GaslessSwapEntrypoint___handlePermit2_unauthorizedSpender();

    /************************************************
     *  IMMUTABLES
     ***********************************************/

    address public immutable DAI;

    IAllowanceTransfer private immutable _permit2;

    IValantisSwapRouter private immutable _swapRouter;

    /************************************************
     *  STORAGE
     ***********************************************/

    mapping(address => bool) private _solverWhitelist;

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

    modifier onlyWhitelistedSolver() {
        if (!_solverWhitelist[msg.sender]) revert GaslessSwapEntrypoint__onlyWhitelistedSolver();
        _;
    }

    /************************************************
     *  EXTERNAL VIEW FUNCTIONS
     ***********************************************/

    function swapRouter() external view override returns (address) {
        return address(_swapRouter);
    }

    function permit2() external view override returns (address) {
        return address(_permit2);
    }

    function isWhitelistedSolver(address _solver) external view override returns (bool) {
        return _solverWhitelist[_solver];
    }

    /************************************************
     *  EXTERNAL FUNCTIONS
     ***********************************************/

    function whitelistSolver(address _solver) external override onlyOwner {
        if (_solver == address(0)) revert GaslessSwapEntrypoint__whitelistSolver_invalidSolver();

        _solverWhitelist[_solver] = true;
    }

    function removeSolver(address _solver) external override onlyOwner {
        _solverWhitelist[_solver] = false;
    }

    function execute(
        GaslessSwapParams calldata _gaslessSwapParams,
        bytes calldata _ownerSignature,
        uint128 _fee,
        TokenPermitInfo calldata _tokenPermitInfo,
        Permit2Info calldata _permit2Info
    ) external override onlyWhitelistedSolver returns (uint256 amountOut) {
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
