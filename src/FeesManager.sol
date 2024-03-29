// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";

contract FeesManager is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    // ====== States ======

    uint256 public feesBps = 5;

    // ====== Constructor ======
    function initialize(address owner) external initializer {
        __Ownable_init(owner);
    }

    // ====== Methods ====== //
    function withdraw(IERC20 token, uint256 amount) external onlyOwner {
        // Native withdrawal
        if (address(token) == address(0)) {
            (bool success,) = payable(owner()).call{value: amount}("");
            require(success, "Failed to transfer ETH to owner");
        } else {
            token.safeTransfer(owner(), amount);
        }
    }

    function setFeeBps(uint256 newBps) external onlyOwner {
        require(newBps >= 0 && newBps <= 10000, "Fees must be between 0 and 10000 BPS (0% to 100%).");
        feesBps = newBps;
    }

    fallback() external payable {}

    receive() external payable {}
}
