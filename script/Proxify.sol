// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * Helper for deploying proxies
 */
import {ITransparentUpgradeableProxy, TransparentUpgradeableProxy} from "@oz/proxy/transparent/TransparentUpgradeableProxy.sol";
import {MultichainScript} from "./Multichain.sol";
import {ProxyAdmin} from "@oz/proxy/transparent/ProxyAdmin.sol";
import {Initializable} from "@oz/proxy/utils/Initializable.sol";

interface OwneableInitializeable {
    function initialize(address owner) external;
}

abstract contract ProxyScript is MultichainScript {
    function upgrade(address proxyAddr, address newImplementation) internal {
        require(
            newImplementation != address(0),
            "Please Set The Implementation Storage Variable First."
        );
        /// Deploy proxy contract with latest impl contract,
        /// Assign self (factory) as admin temporarely
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(
            proxyAddr
        );

        proxy.upgradeTo(newImplementation);
    }

    function proxifyOwnable(OwneableInitializeable newImplementation) internal {
        address multiSig = vm.envAddress("MULTISIG_ADDRESS");

        return
            proxify(
                address(newImplementation),
                multiSig,
                abi.encodeCall(OwneableInitializeable.initialize, (multiSig))
            );
    }

    function proxify(address newImplementation) internal {
        address multiSig = vm.envAddress("MULTISIG_ADDRESS");

        return proxify(newImplementation, multiSig, "");
    }

    function proxify(
        address newImplementation,
        address owner,
        bytes memory initializationCall
    ) internal {

        ProxyAdmin admin = new ProxyAdmin();

        admin.transferOwnership(owner);

        /// Deploy proxy contract with latest impl contract,
        /// Assign self (factory) as admin temporarely
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(
            address(
                new TransparentUpgradeableProxy(
                    address(newImplementation),
                    address(admin),
                    initializationCall
                    // abi.encodeCall(Initializable.initialize, (multiSig))
                )
            )
        );

        (proxy);
    }
}
