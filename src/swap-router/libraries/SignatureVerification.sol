// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC1271 } from '../interfaces/IERC1271.sol';

/**
    @notice Verification of ECDSA signatures for EOAs and smart contracts (EIP 1271).
    @dev Ported from: https://github.com/Uniswap/permit2/blob/main/src/libraries/SignatureVerification.sol
 */
library SignatureVerification {
    /**
        @notice Thrown when the passed in signature is not a valid length
     */
    error InvalidSignatureLength();

    /**
        @notice Thrown when the recovered signer is equal to the zero address
     */
    error InvalidSignature();

    /**
        @notice Thrown when the recovered signer does not equal the claimedSigner
     */
    error InvalidSigner();

    /**
        @notice Thrown when the recovered contract signature is incorrect
     */
    error InvalidContractSignature();

    bytes32 constant UPPER_BIT_MASK = (0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

    function verify(bytes calldata signature, bytes32 hash, address claimedSigner) internal view {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (claimedSigner.code.length == 0) {
            if (signature.length == 65) {
                (r, s) = abi.decode(signature, (bytes32, bytes32));
                v = uint8(signature[64]);
            } else if (signature.length == 64) {
                // EIP-2098
                bytes32 vs;
                (r, vs) = abi.decode(signature, (bytes32, bytes32));
                s = vs & UPPER_BIT_MASK;
                v = uint8(uint256(vs >> 255)) + 27;
            } else {
                revert InvalidSignatureLength();
            }

            // Prevent Signature malleability attacks
            if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
                revert InvalidSignature();
            }

            address signer = ecrecover(hash, v, r, s);
            if (signer == address(0)) revert InvalidSignature();
            if (signer != claimedSigner) revert InvalidSigner();
        } else {
            bytes4 magicValue = IERC1271(claimedSigner).isValidSignature(hash, signature);
            if (magicValue != IERC1271.isValidSignature.selector) revert InvalidContractSignature();
        }
    }
}
