// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Test} from "forge-std/Test.sol";
import {PerpieWallet} from "../src/Wallet.sol";
import {PerpieFactory} from "../src/Factory.sol";
import "forge-std/console.sol";
import {ITransparentUpgradeableProxy} from "@oz/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Transaction} from "../src/Types.sol";
import {Nonces} from "../src/libs/Nonces.sol";

/**
 * Tests for the Perpie smart wallet FACTORY
 */

contract PerpieFactoryTest is Test {
    PerpieFactory public factory;
    PerpieWallet public wallet;

    uint256 privKey = 4919244124;

    address Bob = vm.addr(privKey);

    function setUp() external {
        factory = new PerpieFactory();
        PerpieWallet walletImpl = new PerpieWallet();
        factory.upgradeWalletVersion(address(walletImpl));

        wallet = factory.deploy(Bob);
    }

    function testWalletOwner() external {
        assertEq(
            wallet.owner(),
            Bob,
            "[PerpieFactoryTest]: Deployed, but wallet's owner mismatch"
        );
    }

    function testTxnsSigsLenMustMatch() external {
        Transaction[] memory txns = new Transaction[](4);

        bytes[] memory sigs = new bytes[](3);

        vm.expectRevert();
        wallet.executeTransactions(txns, sigs);
    }

    function testTxnMustHaveValidSig() external {
        uint256 currentNonce = wallet.nonce();
        Transaction memory txn = Transaction({
            to: address(500),
            callData: abi.encodePacked(
                "Your Mom",
                uint256(5325),
                "Penis",
                true,
                false,
                "KEKKK",
                address(412412)
            ),
            value: 0,
            nonce: currentNonce
        });

        // Invalid sig
        bytes memory sig = signFakeTxn(txn);

        Transaction[] memory txns = new Transaction[](1);
        bytes[] memory sigs = new bytes[](1);

        txns[0] = txn;

        // Invalid sig
        sigs[0] = sig;

        vm.expectRevert();
        wallet.executeTransactions(txns, sigs);

        sigs[0] = signTxn(txn);

        // Should go through
        wallet.executeTransactions(txns, sigs);
    }

    function testReplayAttack() external {
        uint256 currentNonce = wallet.nonce();

        Transaction memory txn = Transaction({
            to: address(500),
            callData: abi.encodePacked(
                "Your Mom",
                uint256(5325),
                "Penis",
                true,
                false,
                "KEKKK",
                address(412412)
            ),
            value: 0,
            nonce: currentNonce
        });

        // Invalid sig
        bytes memory sig = signTxn(txn);

        Transaction[] memory txns = new Transaction[](1);
        bytes[] memory sigs = new bytes[](1);

        txns[0] = txn;

        sigs[0] = sig;

        wallet.executeTransactions(txns, sigs);

        // Sig has been used so txn must revert (since we only used 1 sig)
        vm.expectRevert(
            bytes.concat(
                Nonces.InvalidAccountNonce.selector,
                abi.encode(wallet.nonce())
            )
        );
        wallet.executeTransactions(txns, sigs);
    }

    function signTxn(
        Transaction memory txn
    ) internal view returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privKey,
            keccak256(
                abi.encodePacked(txn.to, txn.callData, txn.value, txn.nonce)
            )
        );

        sig = abi.encodePacked(r, s, v);
    }

    function signFakeTxn(
        Transaction memory txn
    ) internal view returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privKey + 1,
            keccak256(
                abi.encodePacked(txn.to, txn.callData, txn.value, txn.nonce)
            )
        );

        sig = abi.encodePacked(r, s, v);
    }

    receive() external payable {}
}
