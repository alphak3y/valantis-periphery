// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {SignatureVerification} from "src/swap-router/libraries/SignatureVerification.sol";
import {IERC1271} from "src/swap-router/interfaces/IERC1271.sol";

contract SignatureVerificationHarness {
    function verify(bytes calldata signature, bytes32 hash, address claimedSigner) external view {
        SignatureVerification.verify(signature, hash, claimedSigner);
    }
}

contract SignatureVerificationTest is Test {
    bytes32 constant UPPER_BIT_MASK = (0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

    SignatureVerificationHarness harness;

    function setUp() public {
        harness = new SignatureVerificationHarness();
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function test_verify_reverts() public {
        uint256 signerPrivateKey = 0xA11CE;

        bytes32 randomHash = keccak256(abi.encode(1, 2));

        address signer = vm.addr(signerPrivateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, randomHash);

        // solhint-disable-next-line max-line-length
        bytes memory longSignature =
            abi.encodePacked(r, s | 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, v);

        bytes memory invalidSignature = abi.encodePacked(longSignature, uint256(1));

        vm.expectRevert(SignatureVerification.InvalidSignatureLength.selector);

        harness.verify(invalidSignature, randomHash, signer);

        vm.expectRevert(SignatureVerification.InvalidSignature.selector);

        harness.verify(longSignature, randomHash, signer);

        bytes32 vs;
        (r, vs) = vm.signCompact(signerPrivateKey, randomHash);

        bytes memory signature = abi.encode(r, vs);

        harness.verify(signature, randomHash, signer);

        vm.etch(signer, abi.encode(0x12));

        vm.mockCall(
            signer,
            0,
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, randomHash, signature),
            abi.encode(bytes4(abi.encode(12)))
        );

        vm.expectRevert(SignatureVerification.InvalidContractSignature.selector);

        harness.verify(signature, randomHash, signer);

        vm.mockCall(
            signer,
            0,
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, randomHash, signature),
            abi.encode(IERC1271.isValidSignature.selector)
        );

        harness.verify(signature, randomHash, signer);
    }
}
