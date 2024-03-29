// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FeesManager} from "@src/FeesManager.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IExecFromModule, Enum} from "@perpie/interfaces/IExecFromModule.sol";

abstract contract PerpFeesModule {
    // ======= Libs ======= //
    FeesManager immutable FEES_MANAGER;
    string public PROTOCOL_NAME;

    // ======= Events ======= //
    event PerpFeeCharged(
        string indexed protocol,
        uint256 indexed amountUsd,
        uint256 indexed amountTokens,
        address token,
        address account,
        uint256 price
    );

    event PerpFeeAnalytic(uint256 sizeDeltaUsd, uint256 amountIn, bool isLong);

    // ======= Errors ======= //
    error FeeExceedsAmountIn(uint256 fee, uint256 amountIn);
    error FailedToTransferNativeToken(bytes err);
    error TokenFeeChargeFailed();

    // ======= Constructor ======= //
    constructor(FeesManager feesManager, string memory protocolName) {
        FEES_MANAGER = feesManager;
        PROTOCOL_NAME = protocolName;
    }

    // ====== Abstract ====== //
    function _getPrice(address token, bool isLong, uint256 sizeDelta) internal view virtual returns (uint256 price);

    function _usdToToken(address token, uint256 usdAmount, uint256 price)
        internal
        view
        virtual
        returns (uint256 tokenAmount);

    // ====== Internal ====== //
    function _execute(address to, bytes memory data, uint256 value) internal returns (bool success, bytes memory res) {
        (success, res) = _execute(msg.sender, to, data, value);
    }

    function _execute(address account, address to, bytes memory data, uint256 value)
        internal
        returns (bool success, bytes memory res)
    {
        (success, res) = _execute(account, to, data, value, true);
    }

    function _execute(address account, address to, bytes memory data, uint256 value, bool requireSuccess)
        internal
        returns (bool success, bytes memory res)
    {
        (success, res) =
            IExecFromModule(account).execTransactionFromModuleReturnData(to, value, data, Enum.Operation.Call);

        require(!requireSuccess || success, "Module Execution Failed");
    }

    function _chargeFee(address account, address tokenIn, bool isLong, uint256 sizeDeltaUsd, uint256 amountIn)
        internal
        returns (uint256 sizeUsdAfterFees, uint256 amountInAfterFee, uint256 fee, uint256 feeBps)
    {
        (sizeUsdAfterFees, amountInAfterFee, fee, feeBps) =
            _chargeFee(account, tokenIn, isLong, sizeDeltaUsd, amountIn, false);
    }

    function _chargeFee(
        address account,
        address tokenIn,
        bool isLong,
        uint256 sizeDeltaUsd,
        uint256 amountIn,
        bool isNativeCollateral // We allow this overload incase some protocol identifies native token via a diff address
    ) internal returns (uint256 sizeUsdAfterFees, uint256 amountInAfterFee, uint256 fee, uint256 feeBps) {
        {
            feeBps = FEES_MANAGER.feesBps();
            fee = _calculateFee(sizeDeltaUsd, feeBps);

            sizeUsdAfterFees = sizeDeltaUsd - fee;
        }
        uint256 price = _getPrice(tokenIn, isLong, sizeUsdAfterFees);
        uint256 tokenFee = _usdToToken(tokenIn, fee, price);

        if (tokenFee >= amountIn) {
            revert FeeExceedsAmountIn(tokenFee, amountIn);
        }

        amountInAfterFee = amountIn - tokenFee;

        if (isNativeCollateral || _isTokenNative(tokenIn)) {
            _chargeNativeFee(account, tokenFee);
        } else {
            _chargeTokenFee(account, tokenIn, tokenFee);
        }

        _emitPerpFeeCharged(fee, tokenFee, tokenIn, account, price);
        _emitPerpAnalytic(amountIn, sizeDeltaUsd, isLong);
    }

    function _emitPerpFeeCharged(uint256 fee, uint256 tokenFee, address tokenIn, address account, uint256 price)
        internal
    {
        emit PerpFeeCharged(PROTOCOL_NAME, fee, tokenFee, tokenIn, account, price);
    }

    function _emitPerpAnalytic(uint256 sizeDeltaUsd, uint256 amountIn, bool isLong) internal {
        emit PerpFeeAnalytic(sizeDeltaUsd, amountIn, isLong);
    }

    function _chargeNativeFee(address account, uint256 amount) private {
        _execute(account, address(FEES_MANAGER), hex"00", amount, true);
    }

    function _chargeTokenFee(address account, address token, uint256 amount) private {
        (, bytes memory res) =
            _execute(account, token, abi.encodeCall(IERC20.transfer, (address(FEES_MANAGER), amount)), 0, true);

        if (res.length != 0 && !abi.decode(res, (bool))) {
            revert TokenFeeChargeFailed();
        }
    }

    function _transferMessageValue(address account) internal {
        (bool success, bytes memory res) = account.call{value: msg.value}("");

        if (!success) {
            revert FailedToTransferNativeToken(res);
        }
    }

    function _deductFeeBps(uint256 amount, uint256 feeBps) public pure returns (uint256 newAmount) {
        newAmount = amount - _calculateFee(amount, feeBps);
    }

    function _calculateFee(uint256 amount, uint256 feeBps) public pure returns (uint256 fee) {
        fee = (amount * feeBps) / 10000;
    }

    function _isTokenNative(address token) public pure returns (bool isNative) {
        isNative = token == address(0) || token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}
