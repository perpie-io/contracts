// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Test} from "forge-std/Test.sol";
import {PerpieWallet} from "../src/Wallet.sol";

/**
 * Tests for the Perpie smart wallet
 */

contract PerpieWalletTest is Test {
    PerpieWallet public wallet;
    address Bob = address(500);

    function setUp() external {
        wallet = new PerpieWallet(Bob);
    }
}
