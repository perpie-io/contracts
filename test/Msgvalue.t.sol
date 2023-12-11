// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
// import {Test} from "forge-std/Test.sol";
// import {PerpieWallet} from "../src/Wallet.sol";
// import {PerpieFactory} from "../src/Factory.sol";
// import "forge-std/console.sol";
// import {ITransparentUpgradeableProxy} from "@oz/proxy/transparent/TransparentUpgradeableProxy.sol";
// import {Transaction} from "../src/Types.sol";

// contract RandomContract {
//     fallback() external payable {}

//     receive() external payable {}
// }

// contract MsgValue {
//     fallback() external payable {
//         console.log("Msg value", msg.value);
//         payable(address(new RandomContract())).call{value: msg.value}(hex"00");
//         console.log("Msg value", msg.value);
//     }

//     receive() external payable {
//         // payable(address(new RandomContract())).call{value: msg.value}(hex"00");
//     }
// }

// /**
//  * Tests for the Perpie smart wallet FACTORY
//  */

// contract MsgValueTest is Test {
//     function testIsMsgValueshit() external {
//         MsgValue contractValue = new MsgValue();

//         vm.deal(address(this), 1 ether);

//         payable(address(contractValue)).call{value: 1 ether}(hex"00");

//         console.log(address(contractValue).balance);
//     }
// }
