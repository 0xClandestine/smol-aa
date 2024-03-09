// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { HuffDeployer } from "foundry-huff/HuffDeployer.sol";

contract AccountTest is Test {
    address account;
    uint256 number;

    function setUp() public virtual {
        account = HuffDeployer.deploy_with_args("Account", abi.encode(address(this)));
        vm.label(account, "Account");
        vm.label(address(this), "AccountTest");
    }

    function add(uint256 a, uint256 b) public payable virtual {
        number = a + b;
    }

    receive() external payable virtual { }
}

contract AccountCallTest is AccountTest {
    function test_AccessControl(address notOwner) public virtual {
        if (msg.sender != address(this)) {
            bytes memory header = abi.encode(0, address(this), 0);
            bytes memory data =
                abi.encodePacked(header, this.add.selector, uint256(420), uint256(69));
            vm.prank(notOwner);
            (bool s,) = account.call(data);
            assertTrue(!s);
        }
    }

    function test_Correctness(uint256 value, uint256 a, uint256 b) public virtual {
        value %= type(uint96).max;
        a %= type(uint96).max;
        b %= type(uint96).max;

        bytes32 addressThisBytes32 = bytes32(uint256(uint160(address(this))));
        assertEq(vm.load(account, addressThisBytes32), addressThisBytes32);

        vm.deal(address(this), 0);
        vm.deal(account, value);

        bytes memory header = abi.encode(0, address(this), value);
        bytes memory data = abi.encodePacked(header, this.add.selector, a, b);
        (bool s,) = account.call(data);

        assertTrue(s);
        assertEq(number, a + b);
        assertEq(address(this).balance, value);
    }
}
