// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

library NonceBitmap {
    error NonceBitmap__consumeNonce_InvalidNonce();

    function consumeNonce(mapping(uint256 => uint256) storage nonces, uint256 nonce) internal {
        uint256 wordPosition = uint248(nonce >> 8);
        uint256 bitPosition = uint8(nonce);

        uint256 bit = 1 << bitPosition;

        uint256 flipped = nonces[wordPosition] ^= bit;

        if (flipped & bit == 0) revert NonceBitmap__consumeNonce_InvalidNonce();
    }
}
