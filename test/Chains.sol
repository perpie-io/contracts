// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract ForkTest is Test {
    uint256 public ARBITRUM;

    function setUp() public virtual {
        ARBITRUM = vm.createFork("https://arb1.arbitrum.io/rpc");
    }

    constructor() {
        ARBITRUM = vm.createFork("https://arb1.arbitrum.io/rpc");
    }
}

contract ArbiTest is ForkTest {
    function setUp() public virtual override {
        console.log("Start Setup");
        super.setUp();
        console.log("Selecgt Fork");
        vm.selectFork(ARBITRUM);
        console.log("New ArbySysMock");
        ArbSysMock arbSysMock = new ArbSysMock();
        console.log("vm.etch");
        vm.etch(address(100), address(arbSysMock).code);
        console.log("SER SER");
    }
}

/**
 * USe In tests
 * Mock ArbSys precomp
 */
contract ArbSysMock {
    function arbBlockNumber() external view returns (uint256) {
        return block.number;
    }
}
