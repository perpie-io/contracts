// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Script.sol";
import "../Multichain.sol";
import {PerpieFactory} from "../../src/Factory.sol";

contract DeployFactory is MultichainScript {
    PerpieFactory factory;

    function run() external {
        for (uint256 i; i < CHAINS.length; i++) {
            vm.createSelectFork(CHAINS[i]);
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

            factory = new PerpieFactory();

            vm.stopBroadcast();
        }
    }
}
