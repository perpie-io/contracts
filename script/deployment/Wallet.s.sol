// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Script.sol";
import "../Multichain.sol";
import {PerpieFactory} from "../../src/Factory.sol";
import {PerpieWallet} from "../../src/Wallet.sol";

/**
 * Script to deploy a new PerpieWallet version
 */

contract UpgradeWalletVersion is MultichainScript {
    PerpieFactory[] factories = [
        PerpieFactory(payable(0x656c1A62f0Ef1907560Bcdb59938E08d770cfE06))
    ];

    function run() external {
        for (uint256 i; i < CHAINS.length; i++) {
            vm.createSelectFork(CHAINS[i]);
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

            PerpieFactory factory = factories[i];

            PerpieWallet impl = new PerpieWallet();

            factory.upgradeWalletVersion(address(impl));

            vm.stopBroadcast();
        }
    }
}
