// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { SocialRecovery } from "../src/SocialRecovery.sol";

contract DeploySocialRecovery is Script {
    function computeSalt(bytes32 initCodeHash) internal virtual returns (bytes32 salt) {
        string[] memory ffi = new string[](3);
        ffi[0] = "bash";
        ffi[1] = "create2.sh";
        ffi[2] = vm.toString(initCodeHash);
        vm.ffi(ffi);
        salt = vm.parseBytes32(vm.readLine(".temp"));
        try vm.removeFile(".temp") { } catch { }
    }

    function socialRecoveryInitCodeHash() internal virtual returns (bytes32) {
        return keccak256(abi.encodePacked(type(SocialRecovery).creationCode));
    }

    function run() public virtual returns (SocialRecovery recovery) {
        vm.startBroadcast();
        recovery = new SocialRecovery{ salt: computeSalt(socialRecoveryInitCodeHash()) }();
        vm.stopBroadcast();
    }
}
