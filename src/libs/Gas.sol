// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IPerpieFactory} from "../interfaces/IFactory.sol";

/**
 * Contract to allow sponsoring gas
 */

abstract contract GasFluid {
    // ====== Errors ======
    error InsufficientGasBalance();

    // ====== State ======
    IPerpieFactory immutable factory;

    // ====== Constructor ======
    constructor(IPerpieFactory _factory) {
        factory = _factory;
    }

    // ====== Modifiers ======
    modifier gasless() {
        uint256 startingGas = gasleft();
        // We assume all bytes are non-empty, because an iteration itself would grow the gas too much for it to be worth
        // deducting empty-byte cost
        uint256 intrinsicGasCost = 21000 + (msg.data.length * 16);

        _; // END OF FUNCTION BODY

        uint256 leftGas = gasleft();

        // 2300 for ETH .trasnfer()
        uint256 weiSpent = ((startingGas - leftGas + intrinsicGasCost + 2300) *
            tx.gasprice) + factory.getAdditionalGasCost();

        if (weiSpent > address(this).balance) revert InsufficientGasBalance();

        payable(msg.sender).transfer(weiSpent);
    }
}
