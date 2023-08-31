// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Transaction} from "./Types.sol";
import {ECDSA} from "@oz/utils/cryptography/ECDSA.sol";
import {Ownable} from "@oz/access/Ownable.sol";
import {GasFluid} from "./libs/Gas.sol";
import {Initializable} from "@oz/proxy/utils/Initializable.sol";
import {Nonces} from "./libs/Nonces.sol";

/**
 * Implementation for Perpie's smart wallet (Account Abstraction)
 */
contract PerpieWallet is Ownable, Initializable, GasFluid, Nonces {
    // ====== Errors ======
    error TxnsSigsLenMiss();
    error TransactionFailed(bytes returnData);
    error InvalidSignature();

    // ====== Constructor ======
    function initialize(address owner) external gasless {
        _transferOwnership(owner);
    }

    // ====== Methods ======
    /**
     * executeTransactions
     * Allows for gas-fee execution of transactions, signed
     * by the owner of the smart wallet
     * @param transactions - Array of transactions
     * @param signatures  - Array of signatures for the transactions
     */
    function executeTransactions(
        Transaction[] calldata transactions,
        bytes[] calldata signatures
    ) external gasless {
        if (transactions.length != signatures.length) revert TxnsSigsLenMiss();

        for (uint256 i; i < transactions.length; i++) {
            Transaction memory transaction = transactions[i];
            bytes memory sig = signatures[i];

            if (!isValidSignature(transaction, sig)) revert InvalidSignature();

            (bool success, bytes memory returnData) = address(transaction.to)
                .call{value: transaction.value}(transaction.callData);

            if (!success) revert TransactionFailed(returnData);
        }
    }

    // ====== Internal ======
    /**
     * Verify a Transaction with a signature
     * @param txn - Transaction struct
     * @param sig - Signature of that transaction struct
     * @return isSignatureValid - Whether or not the signature corresponds to the owner of this wallet
     */
    function isValidSignature(
        Transaction memory txn,
        bytes memory sig
    ) internal returns (bool isSignatureValid) {
        (address signer, ) = ECDSA.tryRecover(
            keccak256(
                abi.encodePacked(
                    txn.to,
                    txn.callData,
                    txn.value,
                    _useCheckedNonce(txn.nonce)
                )
            ),
            sig
        );
        isSignatureValid = signer == owner();
    }
}
