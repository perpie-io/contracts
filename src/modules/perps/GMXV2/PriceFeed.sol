// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {DataStore} from "@gmxv2/data/DataStore.sol";
import {Keys} from "@gmxv2/data/Keys.sol";
import {IPriceFeed} from "@gmxv2/oracle/IPriceFeed.sol";
import {Errors} from "@gmxv2/error/Errors.sol";
import {Chain} from "@gmxv2/chain/Chain.sol";
import {SafeCast} from "@oz/utils/math/SafeCast.sol";
import {Precision} from "@gmxv2/utils/Precision.sol";

library GMXV2MedianPriceFeed {
    // We don't verify bid/ask due to these values being passed at order execution and not now,
    // so we get median directly from price feed
    function getPrice(DataStore dataStore, address token) internal view returns (uint256 price) {
        price = _getPriceFeedPrice(dataStore, token);
    }

    function usdToToken(uint256 usdAmount, uint256 price) internal pure returns (uint256 tokenAmount) {
        // Price is divided by token decimals anyway (e.g for $5 its: 5 * 10 ** (USD_DECIMALS - TOKEN_DECIMALS))
        tokenAmount = usdAmount / price;
    }

    function _getPriceFeedPrice(DataStore _dataStore, address token) private view returns (uint256) {
        uint256 currentTimestamp = Chain.currentTimestamp();

        address priceFeedAddress = _dataStore.getAddress(Keys.priceFeedKey(token));
        if (priceFeedAddress == address(0)) {
            revert Errors.InvalidFeedPrice(token, 0);
        }

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        (
            /* uint80 roundID */
            ,
            int256 _price,
            /* uint256 startedAt */
            ,
            uint256 timestamp,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();

        if (_price <= 0) {
            revert Errors.InvalidFeedPrice(token, _price);
        }

        uint256 heartbeatDuration = _dataStore.getUint(Keys.priceFeedHeartbeatDurationKey(token));
        if (currentTimestamp > timestamp && currentTimestamp - timestamp > heartbeatDuration) {
            revert Errors.PriceFeedNotUpdated(token, timestamp, heartbeatDuration);
        }

        uint256 price = SafeCast.toUint256(_price);
        uint256 precision = _getPriceFeedMultiplier(_dataStore, token);

        uint256 adjustedPrice = Precision.mulDiv(price, precision, Precision.FLOAT_PRECISION);

        return adjustedPrice;
    }

    function _getPriceFeedMultiplier(DataStore _dataStore, address token) private view returns (uint256) {
        uint256 multiplier = _dataStore.getUint(Keys.priceFeedMultiplierKey(token));

        if (multiplier == 0) {
            revert Errors.EmptyPriceFeedMultiplier(token);
        }

        return multiplier;
    }
}
