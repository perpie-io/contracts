// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@oz/proxy/transparent/TransparentUpgradeableProxy.sol";
import {MultichainScript} from "../Multichain.sol";
import {FeesManager} from "../../src/FeesManager.sol";
import {ProxyAdmin} from "@oz/proxy/transparent/ProxyAdmin.sol";

contract DeployImplementation is MultichainScript {
    function run() external {
        for (uint256 i; i < CHAINS.length; i++) {
            vm.createSelectFork(CHAINS[i]);
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

            FeesManager newImplementation = new FeesManager();

            (newImplementation);
        }
    }
}

contract UpgradeFeesManager is MultichainScript {
    function run() external {
        for (uint256 i; i < CHAINS.length; i++) {
            vm.createSelectFork(CHAINS[i]);
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

            address feesManagerProxy = vm.envAddress("FEESMANAGER_PROXY_ADDRESS");

            FeesManager newImplementation = new FeesManager();

            /// Deploy proxy contract with latest impl contract,
            /// Assign self (factory) as admin temporarely
            ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(feesManagerProxy);

            (newImplementation);

            proxy.upgradeTo(address(newImplementation));
        }
    }
}

contract DeployFeesManagerCompletelyNew is MultichainScript {
    function run() external {
        for (uint256 i; i < CHAINS.length; i++) {
            vm.createSelectFork(CHAINS[i]);
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

            address multiSig = vm.envAddress("MULTISIG_ADDRESS");

            FeesManager newImplementation = new FeesManager();

            ProxyAdmin admin = new ProxyAdmin();

            admin.transferOwnership(multiSig);

            /// Deploy proxy contract with latest impl contract,
            /// Assign self (factory) as admin temporarely
            ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(
                address(
                    new TransparentUpgradeableProxy(
                        address(newImplementation),
                        address(admin),
                        abi.encodeCall(FeesManager.initialize, (multiSig))
                    )
                )
            );

            (proxy);
        }
    }
}

// forge script ./script/deployment/FeesManager.s.sol:UpgradeFeesManager --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi --with-gas-price 100000000
