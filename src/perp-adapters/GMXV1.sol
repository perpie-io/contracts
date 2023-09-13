// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {PerpieBasePerpAdapter} from "./BasePerpAdapter.sol";
import {FeesManager} from "../FeesManager.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";

contract PerpieGMXV1Adapter is PerpieBasePerpAdapter {
    IPositionRouter internal immutable gmxPositionRouter;
    IOrderBook internal immutable gmxOrderbook;

    bytes32 internal constant PERPIE_GMX_REFERRAL_CODE =
        0x7065727069650000000000000000000000000000000000000000000000000000;

    constructor(
        FeesManager _feesManager,
        IPositionRouter _gmxPositionRouter,
        IOrderBook _gmxOrderbook
    ) PerpieBasePerpAdapter(_feesManager) {
        gmxPositionRouter = _gmxPositionRouter;
        gmxOrderbook = _gmxOrderbook;
    }

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
        uint256 feesBps = feesManager.feesBps();

        uint256 fees = _computeFee(_amountIn, feesBps);

        _chargeTokenFee(_path[0], fees);

        gmxPositionRouter.createIncreasePosition{value: msg.value}(
            _path,
            _indexToken,
            _amountIn - fees,
            _computeNetAmountAfterFees(_minOut, feesBps),
            _computeNetAmountAfterFees(_sizeDelta, feesBps),
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
        uint256 feesBps = feesManager.feesBps();

        uint256 amountIn = msg.value - _executionFee;

        uint256 fees = _computeFee(amountIn, feesBps);

        _chargeEthFee(fees);

        gmxPositionRouter.createIncreasePositionETH{value: msg.value - fees}(
            _path,
            _indexToken,
            _computeNetAmountAfterFees(_minOut, feesBps),
            _computeNetAmountAfterFees(_sizeDelta, feesBps),
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
        uint256 feesBps = feesManager.feesBps();

        if (_shouldWrap) {
            _chargeEthFee(_computeFee(_amountIn, feesBps));
        } else {
            _chargeTokenFee(_path[0], _computeFee(_amountIn, feesBps));
        }

        gmxOrderbook.createIncreaseOrder{
            value: _shouldWrap
                ? msg.value - _computeFee(_amountIn, feesBps)
                : msg.value
        }(
            _path,
            _computeNetAmountAfterFees(_amountIn, feesBps),
            _indexToken,
            _computeNetAmountAfterFees(_minOut, feesBps),
            _computeNetAmountAfterFees(_sizeDelta, feesBps),
            _collateralToken,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee,
            _shouldWrap
        );
    }
}

interface IPositionRouter {
    function increasePositionRequestKeysStart() external view returns (uint256);

    function decreasePositionRequestKeysStart() external view returns (uint256);

    function increasePositionRequestKeys(
        uint256 index
    ) external view returns (bytes32);

    function decreasePositionRequestKeys(
        uint256 index
    ) external view returns (bytes32);

    function executeIncreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function getRequestQueueLengths()
        external
        view
        returns (uint256, uint256, uint256, uint256);

    function getIncreasePositionRequestPath(
        bytes32 _key
    ) external view returns (address[] memory);

    function getDecreasePositionRequestPath(
        bytes32 _key
    ) external view returns (address[] memory);

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);
}

interface IOrderBook {
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
    ) external payable;
}
