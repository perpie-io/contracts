// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {FeesManager} from "../FeesManager.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";

contract PerpieBasePerpAdapter {
    // Not affected by delegatecall as it is immutable (runtime code will have constant value of it)
    FeesManager immutable feesManager;

    constructor(FeesManager _feesManager) {
        feesManager = _feesManager;
    }

    function _computeFee(
        uint256 amount,
        uint256 feeBps
    ) internal pure returns (uint256 fee) {
        fee = (amount * feeBps) / 10000;
    }

    function _computeNetAmountAfterFees(
        uint256 amount,
        uint256 feeBps
    ) internal pure returns (uint256 amountAfterFees) {
        uint256 fee = (amount * feeBps) / 10000;
        amountAfterFees = amount - fee;
    }

    function _chargeTokenFee(address token, uint256 amount) internal {
        IERC20(token).transfer(address(feesManager), amount);
    }

    function _chargeEthFee(uint256 amount) internal {
        (bool success, ) = address(feesManager).call{value: amount}(hex"00");

        require(success, "eth fee fail");
    }
}
