// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import {Test} from "forge-std/Test.sol";
// import {RhinestoneModuleKit, RhinestoneModuleKitLib, RhinestoneAccount} from "modulekit/test/utils/biconomy-base/RhinestoneModuleKit.sol";
// import {PerpFeesModule} from "@perpie/modules/perps/PerpFeesModule.sol";
// import {FeesManager} from "@perpie/FeesManager.sol";
// import {IExecutorManager} from "@rhinestone/modulekit/IExecutor.sol";
// import {IERC20Metadata} from "@oz/token/ERC20/extensions/IERC20Metadata.sol";
// import {GMXV1FeesModule} from "@perpie/modules/perps/GMXV1/Executor.sol";
// import {IPositionRouter, IVault, IOrderBook} from "@perpie/modules/perps/GMXV1/Interfaces.sol";
// import {ArbitrumTest} from "@tests/Chains.sol";

// contract GMXV1FeesModuleTest is ArbitrumTest, RhinestoneModuleKit {
//     using RhinestoneModuleKitLib for RhinestoneAccount;

//     RhinestoneAccount instance;
//     GMXV1FeesModule gmxv1FeeModule;
//     FeesManager feesManager;

//     IPositionRouter positionRouter =
//         IPositionRouter(0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868);
//     IVault vault = IVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);
//     IOrderBook orderbook =
//         IOrderBook(0x09f77E8A13De9a35a7231028187e9fD5DB8a2ACB);

//     IERC20Metadata usdt =
//         IERC20Metadata(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);

//     function setUp() public virtual override {
//         super.setUp();
//         feesManager = new FeesManager();
//         feesManager.setFeeBps(10);

//         // Setup account
//         instance = makeRhinestoneAccount("1");
//         deal(address(instance.account), 10 ether);

//         // Setup executor
//         gmxv1FeeModule = new GMXV1FeesModule(
//             IExecutorManager(address(instance.aux.executorManager)),
//             feesManager,
//             positionRouter,
//             orderbook,
//             vault
//         );

//         // Add executor to account
//         instance.addExecutor(address(gmxv1FeeModule));

//         deal(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, 10 ether);
//     }

//     address private wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

//     function testIncreasePosition(uint256 _sizeDelta, bool _isLong) external {
//         // vm.assume(_sizeDelta > 0);
//         // vm.assume(_sizeDelta * 10 ** 8 > 30000);
//         // uint256 amountIn = (_sizeDelta * 10 ** 8) / 30000 / 10;

//         // vm.expectRevert();
//         // _increasePosition(_sizeDelta, _isLong, amountIn);

//         // deal(address(usdt), address(this), amountIn);
//         // _increasePosition(_sizeDelta, _isLong, amountIn);
//     }

//     function _increasePosition(
//         uint256 _sizeDelta,
//         bool _isLong,
//         uint256 amountIn
//     ) internal {
//         deal(address(usdt), address(this), amountIn);

//         address[] memory path;

//         if (_isLong) {
//             path = new address[](2);
//             path[0] = address(usdt);
//             path[1] = wbtc;
//         } else {
//             path = new address[](1);
//             path[0] = address(usdt);
//         }

//         gmxv1FeeModule.createIncreasePosition(
//             path,
//             wbtc,
//             amountIn,
//             0,
//             _sizeDelta,
//             _isLong,
//             0,
//             positionRouter.minExecutionFee(),
//             bytes32(0),
//             address(0)
//         );
//     }
// }
