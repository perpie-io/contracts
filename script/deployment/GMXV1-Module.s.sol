// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {MultichainScript} from "../Multichain.sol";
import {FeesManager} from "../../src/FeesManager.sol";
import {GMXV1FeesModule} from "@perpie/modules/perps/GMXV1/Simple.sol";
import {IPositionRouter, IOrderBook, IVault} from "@perpie/modules/perps/GMXV1/Interfaces.sol";

contract DeployGmxV1FeesModule is MultichainScript {
    function run() external {
        for (uint256 i; i < CHAINS.length; i++) {
            vm.createSelectFork(CHAINS[i]);
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

            address feesManagerProxy = vm.envAddress(
                "FEESMANAGER_PROXY_ADDRESS"
            );

            IPositionRouter positionRouter = IPositionRouter(
                0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868
            );

            IVault vault = IVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);

            IOrderBook orderBook = IOrderBook(
                0x09f77E8A13De9a35a7231028187e9fD5DB8a2ACB
            );

            GMXV1FeesModule module = new GMXV1FeesModule(
                FeesManager(payable(feesManagerProxy)),
                positionRouter,
                orderBook,
                vault
            );

            (module);
        }
    }
}


// forge script ./script/deployment/GMXV1-Module.s.sol:DeployGmxV1FeesModule --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi
