// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IAllowanceTransfer } from '../interfaces/IAllowanceTransfer.sol';

struct TokenPermitInfo {
    bool isEnabled;
    bytes data;
}

struct Permit2Info {
    bool isEnabled;
    IAllowanceTransfer.PermitBatch permitBatch;
    bytes signature;
}
