// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {TransparentUpgradeableProxy} from "@oz/proxy/transparent/TransparentUpgradeableProxy.sol";

contract MyScript is Script {
    address factory = 0xffc717f423C3c9F1A9304c8047Dbe47947570175;

    function run() external view {
        bytes memory bytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(factory, factory, new bytes(0))
        );

        console.logBytes(bytecode);

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                factory,
                bytes32(
                    abi.encodePacked(0x634176EcC95D326CAe16829d923C1373Df6ECe95)
                ),
                keccak256(bytecode)
            )
        );

        address wallet = address(uint160(uint(hash)));
        console.log(wallet);
    }
}
