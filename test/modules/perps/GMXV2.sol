// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {FeesManager} from "@perpie/FeesManager.sol";
import {IERC20Metadata} from "@oz/token/ERC20/extensions/IERC20Metadata.sol";
import {ArbiTest} from "@tests/Chains.sol";
import {console} from "forge-std/console.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";
import {GMXV2FeesModule} from "@perpie/modules/perps/GMXV2/GMXV2FeesModule.sol";
import {ModularAccount} from "@perpie/interfaces/IExecFromModule.sol";
import {Keys} from "@gmxv2/data/Keys.sol";
import {Oracle} from "@gmxv2/oracle/Oracle.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Market} from "@gmxv2/market/Market.sol";
import {IBaseOrderUtils} from "@gmxv2/order/IBaseOrderUtils.sol";
import {Order} from "@gmxv2/order/Order.sol";
import {Strings} from "@oz/utils/Strings.sol";
import {Market} from "@gmxv2/market/Market.sol";
import {GMXV2MedianPriceFeed} from "@perpie/modules/perps/GMXV2/PriceFeed.sol";
import {OracleUtils} from "@gmxv2/oracle/OracleUtils.sol";
import {Price} from "@gmxv2/price/Price.sol";
import {OrderVault} from "@gmxv2/order/OrderVault.sol";
import {ExchangeRouter} from "@gmxv2/router/ExchangeRouter.sol";
import {Reader} from "@gmxv2/reader/Reader.sol";
import {DataStore} from "@gmxv2/data/DataStore.sol";

contract GMXV2FeesModuleTest is ArbiTest {
    using stdStorage for StdStorage;

    GMXV2FeesModule gmxv2FeeModule;
    FeesManager feesManager;

    ExchangeRouter exchangeRouter = ExchangeRouter(0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8);
    OrderVault orderVault = OrderVault(payable(0x31eF83a530Fde1B38EE9A18093A333D8Bbbc40D5));
    DataStore dataStore = DataStore(0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8);
    Reader reader = Reader(0x60a0fF4cDaF0f6D496d71e0bC0fFa86FE8E6B23c);

    IERC20Metadata usdc = IERC20Metadata(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);

    IERC20Metadata weth = IERC20Metadata(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    IERC20Metadata wbtc = IERC20Metadata(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);

    IERC20Metadata BTC_USDC_MARKET = IERC20Metadata(0x47c031236e19d024b42f8AE6780E44A573170703);

    address smartAccount = 0x1F09480e2389597ef2173AFF050B0B76De37C103;

    address entryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    function setUp() public virtual override {
        super.setUp();

        feesManager = new FeesManager();
        feesManager.setFeeBps(10);
                        console.log("Created Fees Module");


        gmxv2FeeModule =
        new GMXV2FeesModule(feesManager, exchangeRouter, orderVault, reader,dataStore, IERC20(address(weth)), 0xb9e19940Df2D555123253DAf49A33f4E04C31e81);

        console.log("Created Fees Module");
        vm.prank(entryPoint);
        ModularAccount(address(smartAccount)).enableModule(address(gmxv2FeeModule));

        // Reset balances
        deal(address(usdc), smartAccount, 0);
        vm.prank(smartAccount);
        payable(address(69420)).transfer(smartAccount.balance);
    }

    function testIncreasePosition(uint256 _sizeDelta, bool _isLong, uint8 leverage) external {
        _assumeRealisticInputs(leverage, _sizeDelta, usdc);

        // The token amount we input as initial collateral
        uint256 amountIn = _getAmountIn(_sizeDelta, leverage, _isLong, usdc);

        uint256 orderVaultBalanceBefore = usdc.balanceOf(address(orderVault));
        uint256 feesManagerBalanceBefore = usdc.balanceOf(address(feesManager));

        // No tokens in user's wallet
        _increasePosition(_sizeDelta, _isLong, amountIn, true);
        // We give him tokens and now he tries
        _increasePosition(_sizeDelta, _isLong, amountIn, false);

        uint256 expectedFee = estimateFee(_sizeDelta, _isLong, usdc);
        uint256 chargedFee = usdc.balanceOf(address(feesManager)) - feesManagerBalanceBefore;

        assertGt(chargedFee, 0, "Charged fee is 0");

        assertEq(expectedFee, chargedFee, _makeError("Increase Position Charged fee is not the expected fee"));

        uint256 expectedInputAmount = amountIn - expectedFee;

        assertEq(
            usdc.balanceOf(address(orderVault)),
            orderVaultBalanceBefore + expectedInputAmount,
            _makeError("Increase Position - PositionRouter did not receive correct amountIn")
        );

        assertEq(usdc.balanceOf(smartAccount), 0, "Increase Position - Smart Account has USDT left after increase");
    }

    function _increasePosition(uint256 _sizeDelta, bool _isLong, uint256 amountIn, bool expectRevert) internal {
        address[] memory path = _makePath(address(usdc), address(wbtc), _isLong);

        uint256 executionFee = _executionFee();
        uint256 price = _getPrice(address(wbtc), _isLong);
        deal(smartAccount, executionFee);

        vm.startPrank(smartAccount);
        if (expectRevert) {
            vm.expectRevert();
        } else {
            deal(address(usdc), smartAccount, amountIn);
        }
        bytes32 orderKey = gmxv2FeeModule.createOrder(
            IBaseOrderUtils.CreateOrderParams({
                addresses: IBaseOrderUtils.CreateOrderParamsAddresses({
                    receiver: smartAccount,
                    callbackContract: address(0),
                    cancellationReceiver: address(0),
                    uiFeeReceiver: address(feesManager),
                    market: address(BTC_USDC_MARKET),
                    initialCollateralToken: address(usdc),
                    swapPath: path
                }),
                numbers: IBaseOrderUtils.CreateOrderParamsNumbers({
                    sizeDeltaUsd: _sizeDelta,
                    initialCollateralDeltaAmount: 0,
                    triggerPrice: 0,
                    acceptablePrice: _isLong ? price * 100 : 0,
                    executionFee: executionFee,
                    callbackGasLimit: 0,
                    minOutputAmount: 0
                }),
                orderType: Order.OrderType.MarketIncrease,
                decreasePositionSwapType: Order.DecreasePositionSwapType.NoSwap,
                isLong: _isLong,
                shouldUnwrapNativeToken: false,
                referralCode: bytes32(0),
                autoCancel: false
            }),
            amountIn
        );

        exchangeRouter.simulateExecuteOrder(orderKey, _getSimulationPrices());
        vm.stopPrank();
    }

    function _makePath(address, address, bool) internal view returns (address[] memory path) {
        path = new address[](1);
        path[0] = address(BTC_USDC_MARKET);
    }

    function _executionFee() internal pure returns (uint256 executionFee) {
        // We dont really care to lose some ETH its just a test,we just take safest option
        return 1 ether;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function estimateFee(uint256 sizeDelta, bool isLong, IERC20Metadata token) internal view returns (uint256) {
        uint256 feeBps = feesManager.feesBps();

        uint256 sizeFee = (sizeDelta * feeBps) / 10000;

        return GMXV2MedianPriceFeed.usdToToken(sizeFee, _getPrice(address(token), isLong));
    }

    function _assumeRealisticInputs(uint8 leverage, uint256 sizeDelta, IERC20Metadata token) internal view {
        // Realistic leverage
        vm.assume(leverage > uint8(1) && leverage < uint8(50));

        // Min order
        vm.assume(sizeDelta > 110 * 10 ** 30);

        vm.assume(sizeDelta < type(uint256).max / 10 ** token.decimals() + 1);

        uint256 minUsdPurchaseAmount = dataStore.getUint(Keys.MIN_COLLATERAL_USD);

        uint256 usdPurchaseAmount = sizeDelta / leverage;

        // To be safe
        vm.assume(usdPurchaseAmount > minUsdPurchaseAmount * 2);
    }

    function _makeError(string memory message) internal pure returns (string memory err) {
        err = string.concat("[GMXV2FeesModuleTest]: ", message);
    }

    function _getPrice(address token, bool) internal view returns (uint256) {
        return GMXV2MedianPriceFeed.getPrice(dataStore, token);
    }

    function _getMarketPrice(address marketAddress) internal view returns (uint256) {
        DataStore _dataStore = dataStore;
        Market.Props memory market = reader.getMarket(_dataStore, marketAddress);
        address indexToken = market.indexToken;
        return GMXV2MedianPriceFeed.getPrice(dataStore, indexToken);
    }

    function _getAmountIn(uint256 sizeDelta, uint8 leverage, bool isLong, IERC20Metadata token)
        internal
        view
        returns (uint256)
    {
        return (sizeDelta * 10 ** token.decimals()) / (_getPrice(address(token), isLong)) / uint256(leverage);
    }

    function _getSimulationPrices() internal returns (OracleUtils.SimulatePricesParams memory) {
        string[] memory commandParts = new string[](3);

        commandParts[0] =
            "export prices=$(curl -s https://arbitrum-api.gmxinfra.io/signed_prices/latest | jq -r '.signedPrices[] | \"\\(.tokenAddress // \"0\") \\(.minPriceFull // \"0\") \\(.maxPriceFull // \"0\")\"' | tr ' ' ',')";
        commandParts[1] = "array=($(echo \"$prices\" | tr '\\n' ' '))";
        commandParts[2] =
            "python3 -c \"from eth_abi import encode; array = [tuple([line.split(',')[0], int(line.split(',')[1]), int(line.split(',')[2])]) for line in '''$prices'''.strip().split('\\n')]; print('0x' + encode(['bytes[]'], [[encode(['address', 'uint256', 'uint256'], singleInlineArray) for singleInlineArray in array]]).hex())\"";

        bytes memory result = vm.ffi(commandParts);

        bytes[] memory allResults = abi.decode(result, (bytes[]));
        OracleUtils.SimulatePricesParams memory simulationParams = OracleUtils.SimulatePricesParams({
            primaryTokens: new address[](allResults.length),
            primaryPrices: new Price.Props[](allResults.length),
            minTimestamp: 0,
            maxTimestamp: type(uint256).max
        });

        for (uint256 i; i < allResults.length; i++) {
            bytes memory encoded = allResults[i];

            (address tokenAddress, uint256 minPrice, uint256 maxPrice) =
                abi.decode(encoded, (address, uint256, uint256));

            simulationParams.primaryTokens[i] = tokenAddress;
            simulationParams.primaryPrices[i] = Price.Props({min: minPrice, max: maxPrice});
        }

        return simulationParams;
    }
}
