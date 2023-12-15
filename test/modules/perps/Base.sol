// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import {Test} from "forge-std/Test.sol";
// import {FeesManager} from "@perpie/FeesManager.sol";
// import {IExecutorManager} from "@rhinestone/modulekit/IExecutor.sol";
// import {IERC20Metadata} from "@oz/token/ERC20/extensions/IERC20Metadata.sol";

// contract DummyPerpFeesModule is PerpFeesModule {
//     constructor(
//         IExecutorManager executionManager,
//         FeesManager feesManager,
//         string memory protocolName
//     ) PerpFeesModule(executionManager, feesManager, protocolName) {}

//     function _getPrice(
//         address /**token */,
//         bool /**isLong */,
//         uint256 /**sizeDelta */
//     ) internal pure override returns (uint256 price) {
//         price = 50 * 10 ** 30;
//     }

//     function _usdToToken(
//         address token,
//         uint256 usdAmount,
//         uint256 price
//     ) internal view override returns (uint256 tokenAmount) {
//         uint256 decimals = token == address(0)
//             ? 18
//             : IERC20Metadata(token).decimals();
//         tokenAmount = (usdAmount * 10 ** decimals) / price;
//     }
// }

// // @TODO: Test cases for math logic? its simple, is it even needed?
// contract PerpsFeesModuleTest is Test, RhinestoneModuleKit {
//     using RhinestoneModuleKitLib for RhinestoneAccount;

//     RhinestoneAccount instance;
//     PerpFeesModule perpsFeeModule;
//     FeesManager feesManager;
//     string private protocolName = "DontCareDidntAsk";

//     function setUp() public {
//         feesManager = new FeesManager();
//         feesManager.setFeeBps(10);

//         // Setup account
//         instance = makeRhinestoneAccount("1");
//         deal(address(instance.account), 1000 ether);

//         // Setup executor
//         perpsFeeModule = new DummyPerpFeesModule(
//             IExecutorManager(address(instance.aux.executorManager)),
//             feesManager,
//             "Random"
//         );

//         // Add executor to account
//         instance.addExecutor(address(perpsFeeModule));
//     }
// }
