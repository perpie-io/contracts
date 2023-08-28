// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IPerpieWallet} from "./IWallet.sol";

/**
 * Factory of Perpie wallets
 */
interface IPerpieFactory {
    function getAdditionalGasCost()
        external
        view
        returns (uint256 additionalGas);

    function deploy(address owner) external returns (IPerpieWallet wallet);
}
