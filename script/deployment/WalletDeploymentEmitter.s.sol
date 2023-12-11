// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {ITransparentUpgradeableProxy, TransparentUpgradeableProxy} from "@oz/proxy/transparent/TransparentUpgradeableProxy.sol";
import {MultichainScript} from "../Multichain.sol";
import {FeesManager} from "../../src/FeesManager.sol";
import {ProxyAdmin} from "@oz/proxy/transparent/ProxyAdmin.sol";
import {PerpieWalletDeploymentEmitter} from "../../src/WalletDeploymentEmitter.sol";

contract DeployPerpieWalletDeploymentEmitter is MultichainScript {
    function run() external {
        for (uint256 i; i < CHAINS.length; i++) {
            vm.createSelectFork(CHAINS[i]);
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

            PerpieWalletDeploymentEmitter emitter = new PerpieWalletDeploymentEmitter();
            (emitter);
        }
    }
}

// forge script ./script/deployment/WalletDeploymentEmitter.s.sol:DeployPerpieWalletDeploymentEmitter --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi
