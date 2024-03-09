// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { HuffDeployer } from "foundry-huff/HuffDeployer.sol";

contract AccountTest is Test {
    address account;
    bool flagged;

    function test_Account() public virtual {
        vm.label(address(this), "AccountTest");

        account = HuffDeployer.deploy_with_args("Account", abi.encode(address(this)));

        vm.label(account, "Account");

        assertEq(
            vm.load(account, bytes32(uint256(uint160(address(this))))),
            bytes32(uint256(uint160(address(this))))
        );

        vm.deal(account, 1 ether);

        account.call(
            abi.encodePacked(
                abi.encode(0),
                abi.encode(address(this)),
                abi.encode(uint256(1 ether)),
                this.flag.selector
            )
        );

        assertTrue(flagged);
    }

    function flag() public payable virtual {
        flagged = true;
    }

    receive() external payable virtual { }
}
