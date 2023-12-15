// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {RhinestoneModuleKit, RhinestoneModuleKitLib, RhinestoneAccount} from "modulekit/test/utils/biconomy-base/RhinestoneModuleKit.sol";
import {PerpFeesModule} from "@perpie/modules/perps/PerpFeesModule.sol";
import {FeesManager} from "@perpie/FeesManager.sol";
import {IExecutorManager} from "@rhinestone/modulekit/IExecutor.sol";
import {IERC20Metadata} from "@oz/token/ERC20/extensions/IERC20Metadata.sol";
import {GMXV1FeesModule} from "@perpie/modules/perps/GMXV1/Simple.sol";
import {IPositionRouter, IVault, IOrderBook} from "@perpie/modules/perps/GMXV1/Interfaces.sol";
import {ArbitrumTest} from "@tests/Chains.sol";
import {console} from "forge-std/console.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

interface ModularAccount {
    function enableModule(address module) external;
}

contract GMXV1FeesModuleTest is ArbitrumTest {
    using stdStorage for StdStorage;

    GMXV1FeesModule gmxv1FeeModule;
    FeesManager feesManager;

    IPositionRouter positionRouter =
        IPositionRouter(0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868);
    IVault vault = IVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);
    IOrderBook orderbook =
        IOrderBook(0x09f77E8A13De9a35a7231028187e9fD5DB8a2ACB);

    IERC20Metadata usdt =
        IERC20Metadata(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);

    IERC20Metadata weth =
        IERC20Metadata(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    IERC20Metadata wbtc =
        IERC20Metadata(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);

    // @TODO: Fix the Rhinestone bug and use random account
    address smartAccount = 0x1F09480e2389597ef2173AFF050B0B76De37C103;

    address entryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    function setUp() public virtual override {
        super.setUp();
        feesManager = new FeesManager();
        feesManager.setFeeBps(10);

        // Setup executor
        gmxv1FeeModule = new GMXV1FeesModule(
            feesManager,
            positionRouter,
            orderbook,
            vault
        );

        vm.prank(entryPoint);
        ModularAccount(address(smartAccount)).enableModule(
            address(gmxv1FeeModule)
        );

        // Reset balances
        deal(address(usdt), smartAccount, 0);
        vm.prank(smartAccount);
        payable(address(69420)).transfer(smartAccount.balance);
    }

    function testIncreasePosition(
        uint256 _sizeDelta,
        bool _isLong,
        uint8 leverage
    ) external {
        _assumeRealisticInputs(leverage, _sizeDelta, usdt);

        // The token amount we input as initial collateral
        uint256 amountIn = _getAmountIn(_sizeDelta, leverage, _isLong, usdt);

        uint256 positionRouterBalanceBefore = usdt.balanceOf(
            address(positionRouter)
        );

        uint256 feesManagerBalanceBefore = usdt.balanceOf(address(feesManager));

        // No tokens in user's wallet
        _increasePosition(_sizeDelta, _isLong, amountIn, true);
        // We give him tokens and now he tries
        _increasePosition(_sizeDelta, _isLong, amountIn, false);

        uint256 expectedFee = estimateFee(_sizeDelta, _isLong, usdt);
        uint256 chargedFee = usdt.balanceOf(address(feesManager)) -
            feesManagerBalanceBefore;

        assertEq(
            expectedFee,
            chargedFee,
            _makeError("Increase Position Charged fee is not the expected fee")
        );

        uint256 expectedInputAmount = amountIn - expectedFee;

        assertEq(
            usdt.balanceOf(address(positionRouter)),
            positionRouterBalanceBefore + expectedInputAmount,
            _makeError(
                "Increase Position - PositionRouter did not receive correct amountIn"
            )
        );

        assertEq(
            usdt.balanceOf(smartAccount),
            0,
            "Increase Position - Smart Account has USDT left after increase"
        );
    }

    function testIncreasePositionEth(
        uint256 _sizeDelta,
        bool _isLong,
        uint8 leverage
    ) external {
        _assumeRealisticInputs(leverage, _sizeDelta, weth);

        uint256 amountIn = _getAmountIn(_sizeDelta, leverage, _isLong, weth);

        uint256 positionRouterBalanceBefore = weth.balanceOf(
            address(positionRouter)
        );

        uint256 feesManagerBalanceBefore = weth.balanceOf(address(feesManager));

        // No tokens in user's wallet
        _increasePositionETH(_sizeDelta, _isLong, amountIn, true);
        // We give him tokens and now he tries
        _increasePositionETH(_sizeDelta, _isLong, amountIn, false);

        uint256 expectedFee = estimateFee(_sizeDelta, _isLong, weth);
        uint256 chargedFee = address(feesManager).balance -
            feesManagerBalanceBefore;

        assertEq(
            expectedFee,
            chargedFee,
            _makeError(
                "Increase Position ETH - Charged fee is not the expected fee"
            )
        );

        uint256 executionFee = _executionFee();

        uint256 expectedInputAmount = amountIn - expectedFee + executionFee;

        assertEq(
            weth.balanceOf(address(positionRouter)),
            positionRouterBalanceBefore + expectedInputAmount,
            _makeError(
                "Increase Position ETH - PositionRouter did not receive correct amountIn"
            )
        );

        assertEq(
            smartAccount.balance,
            0,
            "Increase Position ETH - Smart Account has ETH left after increase"
        );
    }

    function testIncreaseOrder(
        uint256 _sizeDelta,
        bool _isLong,
        uint8 leverage
    ) external {
        _assumeRealisticInputs(leverage, _sizeDelta, usdt);

        uint256 amountIn = _getAmountIn(_sizeDelta, leverage, _isLong, usdt);

        uint256 vaultBalanceBefore = usdt.balanceOf(address(vault));
        uint256 orderbookBalanceBefore = usdt.balanceOf(address(orderbook));

        uint256 feesManagerBalanceBefore = usdt.balanceOf(address(feesManager));

        // No tokens in user's wallet
        _increaseOrder(_sizeDelta, _isLong, amountIn, true);
        // We give him tokens and now he tries
        _increaseOrder(_sizeDelta, _isLong, amountIn, false);

        uint256 expectedFee = estimateFee(_sizeDelta, _isLong, usdt);
        uint256 chargedFee = usdt.balanceOf(address(feesManager)) -
            feesManagerBalanceBefore;

        assertEq(
            expectedFee,
            chargedFee,
            _makeError("Increase Order - Charged fee is not the expected fee")
        );

        uint256 expectedInputAmount = amountIn - expectedFee;

        console.log(
            "SA, Orderbook, Vault",
            usdt.balanceOf(address(vault)) - vaultBalanceBefore,
            usdt.balanceOf(address(orderbook)) - orderbookBalanceBefore,
            usdt.balanceOf(address(smartAccount))
        );

        uint256 orderbookBalanceDiff = usdt.balanceOf(address(orderbook)) -
            orderbookBalanceBefore;
        uint256 vaultBalanceDiff = usdt.balanceOf(address(vault)) -
            vaultBalanceBefore;

        assertEq(
            _isLong ? vaultBalanceDiff : orderbookBalanceDiff,
            expectedInputAmount,
            _makeError(
                "Increase Order - vault did not receive correct amountIn"
            )
        );

        assertEq(
            smartAccount.balance,
            0,
            "Increase Order - Smart Account has USDT left after increase"
        );
    }

    function _increasePosition(
        uint256 _sizeDelta,
        bool _isLong,
        uint256 amountIn,
        bool expectRevert
    ) internal {
        address[] memory path = _makePath(
            address(usdt),
            address(wbtc),
            _isLong
        );

        uint256 executionFee = _executionFee();
        deal(smartAccount, executionFee);

        vm.startPrank(smartAccount);
        if (expectRevert) {
            vm.expectRevert();
        } else {
            deal(address(usdt), smartAccount, amountIn);
        }
        gmxv1FeeModule.createIncreasePosition{value: executionFee}(
            path,
            address(wbtc),
            amountIn,
            0,
            _sizeDelta,
            _isLong,
            0,
            executionFee,
            bytes32(0),
            address(0)
        );
        vm.stopPrank();
    }

    function _increasePositionETH(
        uint256 _sizeDelta,
        bool _isLong,
        uint256 amountIn,
        bool expectRevert
    ) internal {
        address[] memory path = _makePath(
            address(weth),
            address(wbtc),
            _isLong
        );

        uint256 executionFee = _executionFee();

        deal(smartAccount, executionFee);

        if (expectRevert) {
            vm.expectRevert();
        } else {
            deal(smartAccount, amountIn + executionFee);
        }

        vm.startPrank(smartAccount);

        gmxv1FeeModule.createIncreasePositionETH{
            value: executionFee + amountIn
        }(
            path,
            address(wbtc),
            0,
            _sizeDelta,
            _isLong,
            0,
            executionFee,
            bytes32(0),
            address(0)
        );
        vm.stopPrank();
    }

    function _increaseOrder(
        uint256 _sizeDelta,
        bool _isLong,
        uint256 amountIn,
        bool expectRevert
    ) internal {
        uint256 executionFee = _executionFee();

        deal(smartAccount, executionFee);

        uint256 price = _getPrice(address(usdt), _isLong);

        if (expectRevert) {
            vm.expectRevert();
        } else {
            deal(address(usdt), smartAccount, amountIn);
        }

        vm.startPrank(smartAccount);

        address[] memory path = _makePath(
            address(usdt),
            address(wbtc),
            _isLong
        );

        gmxv1FeeModule.createIncreaseOrder{value: executionFee}(
            path,
            amountIn,
            address(wbtc),
            0,
            _sizeDelta,
            path[0],
            _isLong,
            price + 10,
            true,
            executionFee,
            path[0] == address(weth)
        );
        vm.stopPrank();
    }

    // function _increaseOrderETH(
    //     uint256 _sizeDelta,
    //     bool _isLong,
    //     uint256 amountIn,
    //     bool expectRevert
    // ) internal {
    //     uint256 executionFee = _executionFee();

    //     deal(smartAccount, executionFee);

    //     if (expectRevert) {
    //         vm.expectRevert();
    //     } else {
    //         deal(smartAccount, amountIn + executionFee);
    //     }

    //     uint256 price = _getPrice(address(tokenIn), _isLong);

    //     vm.startPrank(smartAccount);

    //     gmxv1FeeModule.createIncreaseOrder{
    //         value: executionFee +
    //             (address(tokenIn) == address(weth) ? amountIn : 0)
    //     }(
    //         _makePath(address(tokenIn), address(wbtc), _isLong),
    //         amountIn,
    //         address(wbtc),
    //         0,
    //         _sizeDelta,
    //         _isLong ? address(wbtc) : address(usdt),
    //         _isLong,
    //         price + 10,
    //         true,
    //         executionFee,
    //         address(tokenIn) == address(weth)
    //     );
    //     vm.stopPrank();
    // }

    function _makePath(
        address inputToken,
        address indexToken,
        bool isLong
    ) internal pure returns (address[] memory path) {
        if (isLong) {
            path = new address[](2);
            path[0] = address(inputToken);
            path[1] = indexToken;
        } else {
            path = new address[](1);
            path[0] = address(inputToken);
        }
    }

    function _executionFee() internal view returns (uint256 executionFee) {
        // We dont really care to lose some ETH its just a test,we just take safest option
        return
            max(positionRouter.minExecutionFee(), orderbook.minExecutionFee());
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function estimateFee(
        uint256 sizeDelta,
        bool isLong,
        IERC20Metadata token
    ) internal view returns (uint256) {
        uint256 feeBps = feesManager.feesBps();

        uint256 sizeFee = (sizeDelta * feeBps) / 10000;

        return
            (sizeFee * 10 ** token.decimals()) /
            (_getPrice(address(token), isLong));
    }

    function _assumeRealisticInputs(
        uint8 leverage,
        uint256 sizeDelta,
        IERC20Metadata token
    ) internal {
        // Realistic leverage
        vm.assume(leverage > uint8(1) && leverage < uint8(50));

        // Min order
        vm.assume(sizeDelta > 110 * 10 ** 30);

        vm.assume(sizeDelta < type(uint256).max / 10 ** token.decimals() + 1);

        uint256 minUsdPurchaseAmount = orderbook.minPurchaseTokenAmountUsd();

        uint256 usdPurchaseAmount = sizeDelta / leverage;

        // To be safe
        vm.assume(usdPurchaseAmount > minUsdPurchaseAmount * 2);

        address gov = vault.gov();

        vm.startPrank(gov);
        // Be safe in usdg amounts avoid revert

        vault.setTokenConfig(
            address(token),
            token.decimals(),
            vault.tokenWeights(address(token)),
            vault.minProfitBasisPoints(address(token)),
            0,
            vault.stableTokens(address(token)),
            vault.shortableTokens(address(token))
        );

        stdstore
            .target(address(vault))
            .sig("poolAmounts(address)")
            .with_key(address(token))
            .depth(0)
            .checked_write(vault.poolAmounts(address(token)) / 2);
        stdstore
            .target(address(vault))
            .sig("reservedAmounts(address)")
            .with_key(address(token))
            .depth(0)
            .checked_write(vault.poolAmounts(address(token)) / 10);

        vault.setBufferAmount(address(token), type(uint256).max);
        vault.setBufferAmount(address(wbtc), type(uint256).max);

        vm.stopPrank();
    }

    function _makeError(
        string memory message
    ) internal pure returns (string memory err) {
        err = string.concat("[GMXV1FeesModuleTest]: ", message);
    }

    function _getPrice(
        address token,
        bool isLong
    ) internal view returns (uint256) {
        return
            isLong
                ? vault.getMinPrice(address(token))
                : vault.getMaxPrice(address(token));
    }

    function _getAmountIn(
        uint256 sizeDelta,
        uint8 leverage,
        bool isLong,
        IERC20Metadata token
    ) internal view returns (uint256) {
        return
            (sizeDelta * 10 ** token.decimals()) /
            (_getPrice(address(token), isLong)) /
            uint256(leverage);
    }
}
