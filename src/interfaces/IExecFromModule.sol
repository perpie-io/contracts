// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface ModularAccount {
    function enableModule(address module) external;
}

interface IExecFromModule {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) external payable returns (bool success);

    function execTransactionFromModule(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        payable
        returns (bool success);

    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool success, bytes memory returnData);
}
