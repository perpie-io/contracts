// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IPerpieFactory} from "./interfaces/IFactory.sol";
import {IPerpieWallet} from "./interfaces/IWallet.sol";
import {Ownable} from "@oz/access/Ownable.sol";
import {PerpieWallet} from "./Wallet.sol";

/**
 * Factory of Perpie wallets
 */
contract PerpieFactory is IPerpieFactory, Ownable {
    // ======= Methods ====== //
    /**
     * Deploy a Perpie Wallet
     * @param owner - The owner of the Perpie Wallet
     * @return wallet - The newly deployed wallet
     */
    function deploy(
        address owner
    ) external onlyOwner returns (IPerpieWallet wallet) {
        wallet = new PerpieWallet{salt: bytes32(abi.encodePacked(owner))}(
            owner
        );
    }

    // ======= View ====== //
    /**
     * Retreive wallet address based on owner
     * @param owner - Owner of the Perpie Wallet
     * @return wallet - The address of the wallet (computed)
     * @return isDeployed - Whether it's been deployed yet
     */
    function getWallet(
        address owner
    ) external view returns (PerpieWallet wallet, bool isDeployed) {
        bytes memory bytecode = abi.encodePacked(
            type(PerpieWallet).creationCode,
            abi.encode(owner)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                bytes32(abi.encodePacked(owner)),
                keccak256(bytecode)
            )
        );

        wallet = PerpieWallet(address(uint160(uint(hash))));
        isDeployed = address(wallet).code.length > 0;
    }

    /**
     * Get additional gas costs that may incurr within a txn
     * useful for L2's
     */
    function getAdditionalGasCost()
        external
        view
        returns (uint256 additionalGas)
    {}
}
