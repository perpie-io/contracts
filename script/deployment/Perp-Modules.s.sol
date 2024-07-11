// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.18;

// import {MultichainScript} from "../Multichain.sol";
// import {FeesManager} from "../../src/FeesManager.sol";
// import {GMXV2FeesModule} from "@perpie/modules/perps/GMXV2/GMXV2FeesModule.sol";
// import {OrderVault} from "@gmxv2/order/OrderVault.sol";
// import {ExchangeRouter} from "@gmxv2/router/ExchangeRouter.sol";
// import {Reader} from "@gmxv2/reader/Reader.sol";
// import {DataStore} from "@gmxv2/data/DataStore.sol";
// import {IERC20} from "forge-std/interfaces/IERC20.sol";
// import {GMXV1FeesModule} from "@perpie/modules/perps/GMXV1/GMXV1FeesModule.sol";
// import {IPositionRouter, IOrderBook, IVault} from "@perpie/interfaces/GMXV1.sol";

// contract DeployPerpFeesModules is MultichainScript {
//     function run() external onEachChain {
//         address feesManagerProxy = vm.envAddress("FEESMANAGER_PROXY_ADDRESS");

//         ExchangeRouter exchangeRouter = ExchangeRouter(0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8);
//         OrderVault orderVault = OrderVault(payable(0x31eF83a530Fde1B38EE9A18093A333D8Bbbc40D5));
//         DataStore dataStore = DataStore(0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8);
//         Reader reader = Reader(0x60a0fF4cDaF0f6D496d71e0bC0fFa86FE8E6B23c);

//         GMXV2FeesModule gmxv2 =
//         new GMXV2FeesModule(FeesManager(payable(feesManagerProxy)), exchangeRouter, orderVault, reader,dataStore, IERC20(address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1)));

//         IPositionRouter positionRouter = IPositionRouter(0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868);
//         IVault vault = IVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);
//         IOrderBook orderBook = IOrderBook(0x09f77E8A13De9a35a7231028187e9fD5DB8a2ACB);

//         GMXV1FeesModule gmxv1 = new GMXV1FeesModule(
//                 FeesManager(payable(feesManagerProxy)),
//                 positionRouter,
//                 orderBook,
//                 vault
//             );

//         (gmxv2, gmxv1);
//     }
// }

// // forge script ./script/deployment/Perp-Module.s.sol:DeployPerpFeesModules --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi --with-gas-price 100000000
