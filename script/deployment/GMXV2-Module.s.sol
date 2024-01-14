// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MultichainScript} from "../Multichain.sol";
import {FeesManager} from "../../src/FeesManager.sol";
import {GMXV2FeesModule} from "@perpie/modules/perps/GMXV2/GMXV2FeesModule.sol";
import {OrderVault} from "@gmxv2/order/OrderVault.sol";
import {ExchangeRouter} from "@gmxv2/router/ExchangeRouter.sol";
import {Reader} from "@gmxv2/reader/Reader.sol";
import {DataStore} from "@gmxv2/data/DataStore.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract DeployGmxV2FeesModule is MultichainScript {
    function run() external {
        for (uint256 i; i < CHAINS.length; i++) {
            vm.createSelectFork(CHAINS[i]);
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

            address feesManagerProxy = vm.envAddress("FEESMANAGER_PROXY_ADDRESS");

            ExchangeRouter exchangeRouter = ExchangeRouter(0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8);
            OrderVault orderVault = OrderVault(payable(0x31eF83a530Fde1B38EE9A18093A333D8Bbbc40D5));
            DataStore dataStore = DataStore(0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8);
            Reader reader = Reader(0x60a0fF4cDaF0f6D496d71e0bC0fFa86FE8E6B23c);
            GMXV2FeesModule gmxv2 =
            new GMXV2FeesModule(FeesManager(payable(feesManagerProxy)), exchangeRouter, orderVault, reader,dataStore, IERC20(address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1)));

            (gmxv2);
        }
    }
}

// forge script ./script/deployment/GMXV2-Module.s.sol:DeployGmxV2FeesModule --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi --with-gas-price 100000000
