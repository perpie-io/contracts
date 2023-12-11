// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract PerpieWalletDeploymentEmitter {
    event PerpieAccountDeployed(address indexed walletAddress);

    function emitPerpieWalletDeployed() external {
        address smartAccountAddress = msg.sender;
        emit PerpieAccountDeployed(smartAccountAddress);
    }
}
