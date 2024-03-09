// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { Test, console2 } from "forge-std/Test.sol";
import { Merkle } from "murky/src/Merkle.sol";
import { DeploySocialRecovery, SocialRecovery } from "../script/SocialRecovery.s.sol";

contract SocialRecoveryTest is Test {
    event SetHashFor(address indexed account, bytes32 hash);
    event HandoverInitiated(address indexed account, bytes32 root, uint256 wait);

    SocialRecovery public recovery;
    Merkle public m;

    function setUp() public virtual {
        recovery = new DeploySocialRecovery().run();
        vm.label(address(recovery), "SocialRecovery");
        m = new Merkle();
        vm.label(address(m), "Merkle");
    }
}

contract DeployTest is SocialRecoveryTest {
    function test_Create2() public virtual {
        // Assert `SocialRecovery` address has at least 6 leading zeros.
        assertGt(type(uint136).max, uint160(address(recovery)));
        console2.log("SocialRecovery: ", address(recovery));
    }
}

contract SetHashForTest is SocialRecoveryTest {
    function testFuzz_SetHashFor(address account, bytes32 hash) public virtual {
        vm.startPrank(account);
        vm.expectEmit(true, true, true, false);
        emit SetHashFor(account, hash);
        recovery.setHash(hash);
        assertEq(recovery.hashFor(account), hash);
    }
}

contract InitiateHandoverTest is SocialRecoveryTest {
    function test_InitiateHandover() public virtual {
        address account = vm.addr(1);
        address recoverer = vm.addr(2);

        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = bytes20(recoverer);
        leaves[1] = bytes20(recoverer);

        uint96 wait = 30 days;
        bytes32 root = m.getRoot(leaves);
        bytes32 hash = recovery.hashFor(account, root, wait);

        vm.startPrank(account);
        recovery.setHash(hash);

        vm.startPrank(recoverer);
        vm.expectEmit(true, true, true, false);
        emit HandoverInitiated(account, root, wait);
        recovery.initiateHandover(account, root, wait, m.getProof(leaves, 1));

        (address who, uint256 when) = recovery.recoveryFor(account);
        assertEq(recoverer, who);
        assertEq(block.timestamp + wait, when);
    }
}

contract hashForTest is SocialRecoveryTest {
    function testFuzz_hashFor(address account, bytes32 root, uint256 epoch) public virtual {
        assertEq(
            keccak256(abi.encodePacked(account, root, epoch)),
            recovery.hashFor(account, root, epoch)
        );
    }
}
