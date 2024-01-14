// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

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
        super.setUp();
        vm.selectFork(ARBITRUM);
        ArbSysMock arbSysMock = new ArbSysMock();
        vm.etch(address(100), address(arbSysMock).code);
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
