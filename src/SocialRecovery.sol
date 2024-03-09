// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { MerkleProofLib } from "solady/utils/MerkleProofLib.sol";

// Usage:
// 1) Register the recovery hash.
// 2) For recovery, disclose the unrevealed values, and wait for the specified duration.
// 3) If recovery is not objected to within the designated period, proceed with the recovery
// process.

/// @title Social Recovery
/// @notice This contract provides functionality for social recovery.
contract SocialRecovery {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EVENTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `hashFor` `account` is mutated to `hash`.
    event SetHashFor(address indexed account, bytes32 hash);

    event HandoverInitiated(address indexed account, bytes32 root, uint256 wait);

    /// @dev `keccak256(bytes("SetHashFor(address,bytes32)"))`.
    uint256 private constant _SET_HASH_FOR_SIGNATURE =
        0x1f7f42a0079c207f9ea1287d19f543af1e3ddf406245d07ebe1716d472a900d0;

    /// @dev `keccak256(bytes("HandoverInitiated(address,bytes32,uint256)"))`.
    uint256 private constant _HANDOVER_INITIATED_SIGNATURE =
        0x1bc2b95072b8bb23cadbbfb338d7e3ac06577abe02f92353708ae738084a50bd;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error InvalidProof();

    error InvalidRecoveryHash(); // 0x95e2e674

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The recovery slot for `account` is given by:
    /// ```
    ///     mstore(0x0c, _RECOVERY_SLOT_SEED)
    ///     mstore(0x00, account)
    ///     let recoverySlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _RECOVERY_SLOT_SEED = 0x4834929f;

    /// @notice Returns the recovery hash for `account`.
    function hashFor(address account) public view virtual returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            hash := sload(account)
        }
    }

    /// @notice Returns the recoverer and the time when recovery becomes possible for `account`.
    /// @param account The address for which recovery information is queried.
    /// @return recoverer The address of the potential recoverer.
    /// @return when The time when recovery becomes possible.
    function recoveryFor(address account)
        public
        view
        virtual
        returns (address recoverer, uint96 when)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache recovery seed in memory for recovery slot.
            mstore(0x0c, _RECOVERY_SLOT_SEED)
            // Cache `account` in memory for recovery slot.
            mstore(0x00, account)
            // Load recovery info from storage and cache in memory.
            mstore(0x00, sload(keccak256(0x0c, 0x20)))
            // Parse `recoverer`.
            recoverer := shr(0x60, mload(0x00))
            // Parse `when`.
            when := and(mload(0x00), sub(shl(0x60, 1), 1))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ACTIONS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sets the value of `hashFor` `account` to `hash`.
    function _setHashFor(address account, bytes32 hash) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Mutate `hashFor` `account` in storage.
            sstore(account, hash)
            // Cache `hash` in memory for event.
            mstore(0x00, hash)
            // Emit `SetHashFor` event.
            log2(0x00, 0x20, _SET_HASH_FOR_SIGNATURE, account)
        }
    }

    /// @notice Sets the value of `hashFor` caller to `hash`.
    /// @dev Emits a `SetHashFor` event.
    /// @param hash The new value to set `hashFor` to.
    function setHash(bytes32 hash) public virtual {
        _setHashFor(msg.sender, hash);
    }

    function initiateHandover(address account, bytes32 root, uint96 wait, bytes32[] calldata proof)
        external
        virtual
        returns (bytes32 hash)
    {
        // Assert caller is a valid recoverer.
        if (!MerkleProofLib.verifyCalldata(proof, root, bytes20(msg.sender))) revert InvalidProof();
        /// @solidity memory-safe-assembly
        assembly {
            // Cache free memory pointer.
            let m := mload(0x40)
            // Copy packed calldata to memory.
            calldatacopy(m, 0x10, 0x54)

            // Cache computed `hash`.
            hash := keccak256(m, 0x54)

            // Assert computed `hash` is valid.
            if iszero(eq(hash, sload(account))) {
                mstore(0x00, 0x95e2e674) // `InvalidRecoveryHash()`.
                revert(0x1c, 0x04)
            }

            // Cache recovery seed in memory for recovery slot.
            mstore(0x0c, _RECOVERY_SLOT_SEED)
            // Cache `account` in memory for recovery slot.
            mstore(0x00, account)
            // Hash recovery slot and store `abi.encodePacked(msg.sender, wait)`.
            sstore(keccak256(0x0c, 0x20), or(shl(0x60, caller()), add(timestamp(), wait)))

            // Cache `root` in memory for event.
            mstore(0x00, root)
            // Cache `wait` in memory for event.
            mstore(0x20, wait)
            // Emit `HandoverInitiated` event.
            log2(0x00, 0x40, _HANDOVER_INITIATED_SIGNATURE, account)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         READ-ONLY                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Returns the recovery hash for `account` given `root`, and `wait`
    /// @dev keccak256( account | root | wait )
    function hashFor(
        address, // account
        bytes32, // root
        uint256 // wait
    ) public pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache free memory pointer.
            let m := mload(0x40)
            // Copy packed calldata to memory.
            calldatacopy(m, 0x10, 0x54)
            // Compute and cache `hash` for return.
            hash := keccak256(m, 0x54)
        }
    }
}
