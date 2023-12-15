// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
// import {FeesManager} from "@src/FeesManager.sol";
// import {ERC20ModuleKit} from "@rhinestone/modulekit/integrations/ERC20Actions.sol";
// import {IERC20} from "forge-std/interfaces/IERC20.sol";
// import {ExecutorBase} from "@rhinestone/modulekit/ExecutorBase.sol";
// import {IExecutorManager, ExecutorAction, ModuleExecLib} from "@rhinestone/modulekit/IExecutor.sol";

// abstract contract PerpFeesModule is ExecutorBase {
//     // ======= Libs ======= //
//     using ModuleExecLib for IExecutorManager;
//     FeesManager immutable FEES_MANAGER;
//     string public PROTOCOL_NAME;
//     IExecutorManager immutable EXECUTION_MANAGER;

//     // ======= Events ======= //
//     event PerpFeeCharged(
//         string indexed protocol,
//         address indexed token,
//         uint256 indexed amount,
//         address account
//     );

//     // ======= Constructor ======= //
//     constructor(
//         IExecutorManager executionManager,
//         FeesManager feesManager,
//         string memory protocolName
//     ) {
//         EXECUTION_MANAGER = executionManager;
//         FEES_MANAGER = feesManager;
//         PROTOCOL_NAME = protocolName;
//     }

//     // ====== Module Metadata ====== //
//     function name() external view override returns (string memory _name) {
//         _name = string.concat("Perpie:PerpFees:", PROTOCOL_NAME);
//     }

//     function version() external pure override returns (string memory _version) {
//         _version = "1";
//     }

//     function metadataProvider()
//         external
//         pure
//         override
//         returns (uint256 providerType, bytes memory location)
//     {
//         providerType = 0;
//         location = new bytes(0);
//     }

//     function requiresRootAccess()
//         external
//         pure
//         override
//         returns (bool _requiresRootAccess)
//     {
//         _requiresRootAccess = false;
//     }

//     // ====== Abstract ====== //
//     function _getPrice(
//         address token,
//         bool isLong,
//         uint256 sizeDelta
//     ) internal view virtual returns (uint256 price);

//     function _usdToToken(
//         address token,
//         uint256 usdAmount,
//         uint256 price
//     ) internal view virtual returns (uint256 tokenAmount);

//     // ====== Internal ====== //
//     function _chargeFee(
//         address account,
//         address tokenIn,
//         bool isLong,
//         uint256 sizeDeltaUsd,
//         uint256 amountIn
//     )
//         internal
//         returns (
//             uint256 sizeUsdAfterFees,
//             uint256 amountInAfterFee,
//             uint256 fee,
//             uint256 feeBps
//         )
//     {
//         (sizeUsdAfterFees, amountInAfterFee, fee, feeBps) = _chargeFee(
//             account,
//             tokenIn,
//             isLong,
//             sizeDeltaUsd,
//             amountIn,
//             false
//         );
//     }

//     function _chargeFee(
//         address account,
//         address tokenIn,
//         bool isLong,
//         uint256 sizeDeltaUsd,
//         uint256 amountIn,
//         bool isNativeCollateral
//     )
//         internal
//         returns (
//             uint256 sizeUsdAfterFees,
//             uint256 amountInAfterFee,
//             uint256 fee,
//             uint256 feeBps
//         )
//     {
//         feeBps = FEES_MANAGER.feesBps();
//         fee = _calculateFee(sizeDeltaUsd, feeBps);

//         sizeUsdAfterFees = sizeDeltaUsd - fee;
//         uint256 price = _getPrice(tokenIn, isLong, sizeUsdAfterFees);
//         uint256 tokenFee = _usdToToken(tokenIn, fee, price);

//         amountInAfterFee = amountIn - tokenFee;

//         // We allow this overload incase some protocol identifies native token via a diff address
//         if (isNativeCollateral || _isTokenNative(tokenIn)) {
//             EXECUTION_MANAGER.exec(
//                 account,
//                 ExecutorAction({
//                     to: payable(address(FEES_MANAGER)),
//                     value: fee,
//                     data: hex"00"
//                 })
//             );
//         } else {
//             EXECUTION_MANAGER.exec(
//                 account,
//                 ERC20ModuleKit.transferAction({
//                     token: IERC20(tokenIn),
//                     to: address(FEES_MANAGER),
//                     amount: amountInAfterFee
//                 })
//             );
//         }

//         emit PerpFeeCharged(PROTOCOL_NAME, tokenIn, fee, account);
//     }

//     function _deductFeeBps(
//         uint256 amount,
//         uint256 feeBps
//     ) public pure returns (uint256 newAmount) {
//         newAmount = amount - _calculateFee(amount, feeBps);
//     }

//     function _calculateFee(
//         uint256 amount,
//         uint256 feeBps
//     ) public pure returns (uint256 fee) {
//         fee = (amount * feeBps) / 10000;
//     }

//     function _isTokenNative(address token) public pure returns (bool isNative) {
//         isNative = token == address(0) || token == ERC20ModuleKit.ETH_ADDR;
//     }
// }
