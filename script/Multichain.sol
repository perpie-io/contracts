/**
 * All supported chains
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Script.sol";

contract MultichainScript is Script {
    string[] internal CHAINS = [vm.envString("ARBITRUM_RPC_URL")];

    modifier onEachChain() {
        for (uint256 i; i < CHAINS.length; i++) {
            vm.createSelectFork(CHAINS[i]);
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
            _; // Run function body on each chain
        }
    }
}
