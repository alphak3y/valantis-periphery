// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IAllowanceTransfer} from "../interfaces/IAllowanceTransfer.sol";

/**
 * @notice Struct containing data to use for ERC20 permit based approvals.
 *     @param isEnabled True if the token contains a permit function and needs to approve Permit2.
 *     @param data Either ERC2612Permit or DaiPermit compliant payload.
 */
struct TokenPermitInfo {
    bool isEnabled;
    bytes data;
}

/**
 * @notice Struct contain data to use for Permit2 to approve Swap Router.
 *     @param isEnabled False in case this should be skipped.
 *     @param permitBatch Parameters for Permit2::permit.
 *     @param signature Parameter for Permit2::permit.
 */
struct Permit2Info {
    bool isEnabled;
    IAllowanceTransfer.PermitBatch permitBatch;
    bytes signature;
}
