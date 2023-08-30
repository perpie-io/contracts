// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {TransparentUpgradeableProxy} from "@oz/proxy/transparent/TransparentUpgradeableProxy.sol";

contract MyScript is Script {
    function run() external view {
        console.logBytes(type(TransparentUpgradeableProxy).creationCode);
    }
}
