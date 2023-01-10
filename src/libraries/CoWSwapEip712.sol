// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity =0.8.17;

/// @title CoW Swap EIP-712 Encoding Library
/// @author CoW Swap Developers
library CoWSwapEip712 {
    /// @dev Value returned by a call to `isValidSignature` if the signature
    /// was verified successfully. The value is defined in EIP-1271 as:
    /// bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    /// @dev The EIP-712 domain type hash used for computing the domain separator.
    bytes32 private constant DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @dev The EIP-712 domain name used for computing the domain separator.
    bytes32 private constant DOMAIN_NAME = keccak256("Gnosis Protocol");

    /// @dev The EIP-712 domain version used for computing the domain separator.
    bytes32 private constant DOMAIN_VERSION = keccak256("v2");

    /// @dev Computes the EIP-712 domain separator of the CoW Swap settlement contract on the current network.
    ///
    /// @param cowSwapAddress The address of the CoW Swap settlement contract for which to compute the domain separator.
    /// Note that there are no checks to verify that the input address points to an actual contract.
    /// @return The domain separator of the settlement contract for the input address as computed by the settlement
    /// contract internally.
    function domainSeparator(address cowSwapAddress) internal view returns (bytes32) {
        // NOTE: Currently, the only way to get the chain ID in solidity is using assembly.
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        return keccak256(abi.encode(DOMAIN_TYPE_HASH, DOMAIN_NAME, DOMAIN_VERSION, chainId, cowSwapAddress));
    }
}
