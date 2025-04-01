// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @notice EIP712 helpers for Valantis Swap Router.
 *     @dev Adapted from: https://github.com/Uniswap/permit2/blob/main/src/EIP712.sol
 */
contract EIP712 {
    // Cache the domain separator as an immutable value, but also store the chain id that it
    // corresponds to, in order to invalidate the cached domain separator if the chain id changes.
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    // solhint-disable-next-line var-name-mixedcase
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private constant _HASHED_NAME = keccak256("ValantisSwapRouter");

    bytes32 private constant _DOMAIN_HASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    constructor() {
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(_DOMAIN_HASH, _HASHED_NAME);
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == _CACHED_CHAIN_ID
            ? _CACHED_DOMAIN_SEPARATOR
            : _buildDomainSeparator(_DOMAIN_HASH, _HASHED_NAME);
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 nameHash) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, block.chainid, address(this)));
    }

    function _hashTypedDataV4(bytes32 intentHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), intentHash));
    }
}
