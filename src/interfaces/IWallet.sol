// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ECDSA} from "@oz/utils/cryptography/ECDSA.sol";
import {Transaction} from "../Types.sol";

/**
 * Implementation for Perpie's smart wallet (Account Abstraction)
 */

interface IPerpieWallet {
    function executeTransactions(
        Transaction[] calldata transactions,
        bytes[] calldata signatures
    ) external;
}
