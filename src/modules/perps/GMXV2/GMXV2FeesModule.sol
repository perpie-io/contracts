// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {PerpFeesModule} from "@perpie/modules/perps/AbstractPerpFeesModule.sol";
import {FeesManager} from "@perpie/FeesManager.sol";
import {Ownable} from "@oz/access/Ownable.sol";
import {ExchangeRouter} from "@gmxv2/router/ExchangeRouter.sol";
import {IBaseOrderUtils} from "@gmxv2/order/IBaseOrderUtils.sol";
import {OrderVault} from "@gmxv2/order/OrderVault.sol";
import {Reader} from "@gmxv2/reader/Reader.sol";
import {DataStore} from "@gmxv2/data/DataStore.sol";
import {GMXV2MedianPriceFeed} from "./PriceFeed.sol";

/**
 * TODO: Integrate V2 Callbacks (afterOrderExecuted, afterOrderCancelled). Keep the funds on here. On afterOrderExecuted,
 * transfer to FeesManager. on afterOrderCancelled, transfer back to sender.
 */
contract GMXV2FeesModule is PerpFeesModule, Ownable {
    // ====== Constants ====== //
    bytes32 internal constant PERPIE_GMX_REFERRAL_CODE =
        0x7065727069650000000000000000000000000000000000000000000000000000;

    IERC20 internal immutable WETH;

    // ====== Variables ====== //
    ExchangeRouter internal exchangeRouter;
    OrderVault internal orderVault;
    Reader internal reader;
    DataStore internal dataStore;

    // ====== Constructor ====== //
    constructor(
        FeesManager _feesManager,
        ExchangeRouter _exchangeRouter,
        OrderVault _orderVault,
        Reader _reader,
        DataStore _dataStore,
        IERC20 weth,
        address owner
    ) PerpFeesModule(_feesManager, "GMXV2") Ownable() {
        setExchangeRouter(_exchangeRouter);
        setOrderVault(_orderVault);
        setReader(_reader);
        setDataStore(_dataStore);
        WETH = weth;
        _transferOwnership(owner);

    }
    // ====== Admin Methods ===== //

    function setExchangeRouter(ExchangeRouter _exchangeRouter) public onlyOwner {
        exchangeRouter = _exchangeRouter;
    }

    function setOrderVault(OrderVault _orderVault) public onlyOwner {
        orderVault = _orderVault;
    }

    function setReader(Reader _reader) public onlyOwner {
        reader = _reader;
    }

    function setDataStore(DataStore _dataStore) public onlyOwner {
        dataStore = _dataStore;
    }

    // ====== Overrides ====== //
    // We don't verify bid/ask due to these values being passed at order execution and not now,
    // so we get median directly from price feed
    function _getPrice(address tokenAddress, bool, uint256) internal view override returns (uint256 price) {
        price = GMXV2MedianPriceFeed.getPrice(dataStore, tokenAddress);
    }

    function _usdToToken(address, uint256 usdAmount, uint256 price)
        internal
        pure
        override
        returns (uint256 tokenAmount)
    {
        tokenAmount = GMXV2MedianPriceFeed.usdToToken(usdAmount, price);
    }

    // ====== Methods ====== //
    function createOrder(IBaseOrderUtils.CreateOrderParams memory params, uint256 amountIn)
        external
        payable
        returns (bytes32 key)
    {
        uint256 fee;
        uint256 feeBps;
        (params.numbers.sizeDeltaUsd, amountIn, fee, feeBps) = _chargeFee(
            msg.sender,
            params.addresses.initialCollateralToken,
            params.isLong,
            params.numbers.sizeDeltaUsd,
            amountIn,
            _isDepositingNativeToken(params)
        );
        if (params.numbers.minOutputAmount != 0) {
            params.numbers.minOutputAmount = _deductFeeBps(params.numbers.minOutputAmount, feeBps);
        }
        _depositCollateralAndExecutionFees(params, amountIn);
        (, bytes memory result) =
            _execute(address(exchangeRouter), abi.encodeCall(exchangeRouter.createOrder, (params)), 0);

        key = abi.decode(result, (bytes32));
    }

    // ====== Internal ====== //
    function _depositCollateralAndExecutionFees(IBaseOrderUtils.CreateOrderParams memory params, uint256 amountIn)
        internal
    {
        address initialCollateralToken = params.addresses.initialCollateralToken;
        uint256 executionFee = params.numbers.executionFee;

        // Native ETH as token in
        if (_isDepositingNativeToken(params)) {
            _sendWnt(executionFee + amountIn);
        } else {
            _sendWnt(executionFee);
            _sendTokens(IERC20(initialCollateralToken), amountIn);
        }
    }

    function _sendWnt(uint256 amt) internal {
        _execute(address(exchangeRouter), abi.encodeCall(exchangeRouter.sendWnt, (address(orderVault), amt)), amt);
    }

    function _sendTokens(IERC20 token, uint256 amt) internal {
        _execute(address(token), abi.encodeCall(IERC20.transfer, (address(orderVault), amt)), 0);
    }

    function _isDepositingNativeToken(IBaseOrderUtils.CreateOrderParams memory params)
        internal
        view
        returns (bool isDepositingNativeToken)
    {
        isDepositingNativeToken =
            params.addresses.initialCollateralToken == address(WETH) && params.shouldUnwrapNativeToken;
    }
}
