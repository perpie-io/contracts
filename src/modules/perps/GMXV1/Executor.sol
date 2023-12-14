// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20ModuleKit} from "@rhinestone/modulekit/integrations/ERC20Actions.sol";
import {ExecutorBase} from "@rhinestone/modulekit/ExecutorBase.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {PerpFeesModule} from "@perpie/modules/perps/PerpFeesModule.sol";
import {IPositionRouter, IOrderBook, IVault} from "./Interfaces.sol";
import {FeesManager} from "@perpie/FeesManager.sol";
import {IExecutorManager} from "@rhinestone/modulekit/IExecutor.sol";

contract GMXV1FeesModule is PerpFeesModule {
    // ====== Variables ====== //
    IPositionRouter internal immutable gmxPositionRouter;
    IOrderBook internal immutable gmxOrderbook;
    IVault internal immutable gmxVault;

    bytes32 internal constant PERPIE_GMX_REFERRAL_CODE =
        0x7065727069650000000000000000000000000000000000000000000000000000;

    constructor(
        IExecutorManager executionManager,
        FeesManager _feesManager,
        IPositionRouter _gmxPositionRouter,
        IOrderBook _gmxOrderbook,
        IVault vault
    ) PerpFeesModule(executionManager, _feesManager, "GMXV1") {
        gmxPositionRouter = _gmxPositionRouter;
        gmxOrderbook = _gmxOrderbook;
        gmxVault = vault;
    }

    // ====== Overrides ====== //
    function _getPrice(
        address token,
        bool isLong,
        uint256 /**sizeDelta */
    ) internal view override returns (uint256 price) {
        price = isLong
            ? gmxVault.getMinPrice(token)
            : gmxVault.getMaxPrice(token);
    }

    function _usdToToken(
        address token,
        uint256 usdAmount,
        uint256 price
    ) internal view override returns (uint256 tokenAmount) {
        tokenAmount = gmxVault.usdToToken(token, usdAmount, price);
    }

    // ====== Methods ====== //
    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 /**_referralCode */,
        address _callbackTarget
    ) external payable {
        uint256 fee;
        uint256 feeBps;
        (_sizeDelta, _amountIn, fee, feeBps) = _chargeFee(
            msg.sender,
            _path[0],
            _isLong,
            _sizeDelta,
            _amountIn
        );

        _minOut = _deductFeeBps(_minOut, feeBps);

        gmxPositionRouter.createIncreasePosition{value: msg.value}(
            _path,
            _indexToken,
            _amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            PERPIE_GMX_REFERRAL_CODE,
            _callbackTarget
        );
    }

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 /**_referralCode */,
        address _callbackTarget
    ) external payable {
        uint256 amountIn = msg.value - _executionFee;
        uint256 fee;
        uint256 feeBps;

        (_sizeDelta, amountIn, fee, feeBps) = _chargeFee(
            msg.sender,
            _path[0],
            _isLong,
            _sizeDelta,
            amountIn
        );

        _minOut = _deductFeeBps(_minOut, feeBps);

        gmxPositionRouter.createIncreasePositionETH{value: amountIn}(
            _path,
            _indexToken,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            PERPIE_GMX_REFERRAL_CODE,
            _callbackTarget
        );
    }

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable {
        uint256 feeBps;
        {
            (_sizeDelta, _amountIn, , feeBps) = _chargeFee(
                msg.sender,
                _path[0],
                _isLong,
                _sizeDelta,
                _amountIn,
                _shouldWrap
            );
        }
        _minOut = _deductFeeBps(_minOut, feeBps);

        gmxOrderbook.createIncreaseOrder{
            value: _shouldWrap ? _amountIn + _executionFee : msg.value
        }(
            _path,
            _amountIn,
            _indexToken,
            _minOut,
            _sizeDelta,
            _collateralToken,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee,
            _shouldWrap
        );
    }
}
