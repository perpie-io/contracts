// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ProxyScript} from "../Proxify.sol";
import {GMXV2OrderCallbackHandler, RoleStore} from "@src/callback/GMXV2/Orders.sol";
import {console} from "forge-std/console.sol";

contract GMXV2OrderCallbackDeployment is ProxyScript {
    function run() external onEachChain {
        address roleStore = 0x3c3d99FD298f679DBC2CEcd132b4eC4d0F5e6e72;
        GMXV2OrderCallbackHandler handler = new GMXV2OrderCallbackHandler(
            RoleStore(roleStore)
        );
        proxify(address(handler));
    }
}

contract GMXV2OrderCallbackUpgrade is ProxyScript {
    function run() external onEachChain {
        address roleStore = 0x3c3d99FD298f679DBC2CEcd132b4eC4d0F5e6e72;
        GMXV2OrderCallbackHandler handler = new GMXV2OrderCallbackHandler(
            RoleStore(roleStore)
        );
        upgrade(0xB5D71c2b03650D7D6e55B71cB31D9d130FfD29d6, address(handler));
    }
}
// forge script ./script/deployment/GMXV2-Order-Callback.s.sol:GMXV2OrderCallbackDeployment --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi --with-gas-price 100000000
