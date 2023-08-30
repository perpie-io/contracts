// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Test} from "forge-std/Test.sol";
import {PerpieWallet} from "../src/Wallet.sol";
import {PerpieFactory} from "../src/Factory.sol";
import "forge-std/console.sol";
import {ITransparentUpgradeableProxy} from "@oz/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Transaction} from "../src/Types.sol";

/**
 * Tests for the Perpie smart wallet FACTORY
 */

contract PerpieFactoryTest is Test {
    PerpieFactory public factory;
    PerpieWallet public walletImpl;
    uint256 privKey = 4919244124;
    address Bob = vm.addr(privKey);

    function setUp() external {
        factory = new PerpieFactory();
        walletImpl = new PerpieWallet();
        factory.upgradeWalletVersion(address(walletImpl));
    }

    function testAddressDetermination() external {
        (PerpieWallet desiredAddress, ) = factory.getWallet(Bob);

        PerpieWallet wallet = factory.deploy(Bob);

        assertEq(
            address(wallet),
            address(desiredAddress),
            "[PerpieFactoryTest]: Desired address != deployed address"
        );
    }

    function testWalletOwner() external {
        PerpieWallet wallet = factory.deploy(Bob);

        assertEq(
            wallet.owner(),
            Bob,
            "[PerpieFactoryTest]: Deployed, but wallet's owner mismatch"
        );
    }

    function testProxyAdminstration() external {
        PerpieWallet wallet = factory.deploy(Bob);

        vm.prank(address(wallet));
        assertEq(
            ITransparentUpgradeableProxy(address(wallet)).admin(),
            address(wallet),
            "Admin is not proxy itself"
        );

        PerpieWallet newImplementation = new PerpieWallet();

        // Not required for the test, just making sure it works
        factory.upgradeWalletVersion(address(newImplementation));

        Transaction memory upgradeTxn = Transaction({
            to: address(wallet),
            value: 0,
            callData: abi.encodeCall(
                ITransparentUpgradeableProxy.upgradeTo,
                (address(newImplementation))
            )
        });

        Transaction[] memory txns = new Transaction[](1);
        txns[0] = upgradeTxn;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privKey,
            keccak256(
                abi.encodePacked(
                    upgradeTxn.to,
                    upgradeTxn.callData,
                    upgradeTxn.value
                )
            )
        );

        bytes[] memory sigs = new bytes[](1);

        sigs[0] = abi.encodePacked(r, s, v);

        wallet.executeTransactions(txns, sigs);

        vm.prank(address(wallet));
        address newImplemented = ITransparentUpgradeableProxy(address(wallet))
            .implementation();

        assertEq(
            newImplemented,
            address(newImplementation),
            "[PerpieFactoryTest]: Upgraded through executeTransactions, but implementation was not correctly upgraded"
        );
    }

    receive() external payable {}
}
