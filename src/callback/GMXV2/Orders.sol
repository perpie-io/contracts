// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IOrderCallbackReceiver} from "@gmxv2/callback/IOrderCallbackReceiver.sol";
import {IDepositCallbackReceiver} from "@gmxv2/callback/IDepositCallbackReceiver.sol";
import {IWithdrawalCallbackReceiver} from "@gmxv2/callback/IWithdrawalCallbackReceiver.sol";
import {Order} from "@gmxv2/order/Order.sol";
import {EventUtils} from "@gmxv2/event/EventUtils.sol";
import {RoleModule} from "@gmxv2/role/RoleModule.sol";
import {RoleStore} from "@gmxv2/role/RoleStore.sol";
import {GMXV2EventEmitter} from "./EventEmitter.sol";
import {Cast} from "@src/utils/Cast.sol";
import {Initializable} from "@oz/proxy/utils/Initializable.sol";

/**
 * Callback Handler For GMXV2 Contracts
 * Currently just emits events
 */
contract GMXV2OrderCallbackHandler is
    IOrderCallbackReceiver,
    GMXV2EventEmitter,
    RoleModule,
    Initializable
{
    // <======= Libs =======>
    using EventUtils for EventUtils.AddressItems;
    using EventUtils for EventUtils.UintItems;
    using EventUtils for EventUtils.IntItems;
    using EventUtils for EventUtils.BoolItems;
    using EventUtils for EventUtils.Bytes32Items;
    using EventUtils for EventUtils.BytesItems;
    using EventUtils for EventUtils.StringItems;
    using Order for Order.Props;

    // <======= Constants =======>
    string constant ORDER_CANCELLED_EVENT_NAME = "GMXV2_ORDER_CANCELLED";

    // <======= Constructor =======>
    constructor(RoleStore roleStore) RoleModule(roleStore) {}

    // <======= Methods =======>
    // @dev called after an order execution
    // @param key the key of the order
    // @param order the order that was executed
    function afterOrderExecution(
        bytes32 key,
        Order.Props memory order,
        EventUtils.EventLogData memory eventData
    ) external view override onlyController {
        key;
        order;
        eventData;
    }

    // @dev called after an order cancellation
    // @param key the key of the order
    // @param order the order that was cancelled
    function afterOrderCancellation(
        bytes32 key,
        Order.Props memory order,
        EventUtils.EventLogData memory /**oldEventData */
    ) external override onlyController {
        EventUtils.EventLogData memory eventData;
        eventData.addressItems.initItems(6);
        eventData.addressItems.setItem(0, "account", order.account());
        eventData.addressItems.setItem(1, "receiver", order.receiver());
        eventData.addressItems.setItem(
            2,
            "callbackContract",
            order.callbackContract()
        );
        eventData.addressItems.setItem(
            3,
            "uiFeeReceiver",
            order.uiFeeReceiver()
        );
        eventData.addressItems.setItem(4, "market", order.market());
        eventData.addressItems.setItem(
            5,
            "initialCollateralToken",
            order.initialCollateralToken()
        );

        eventData.addressItems.initArrayItems(1);
        eventData.addressItems.setItem(0, "swapPath", order.swapPath());

        eventData.uintItems.initItems(10);
        eventData.uintItems.setItem(0, "orderType", uint256(order.orderType()));
        eventData.uintItems.setItem(
            1,
            "decreasePositionSwapType",
            uint256(order.decreasePositionSwapType())
        );
        eventData.uintItems.setItem(2, "sizeDeltaUsd", order.sizeDeltaUsd());
        eventData.uintItems.setItem(
            3,
            "initialCollateralDeltaAmount",
            order.initialCollateralDeltaAmount()
        );
        eventData.uintItems.setItem(4, "triggerPrice", order.triggerPrice());
        eventData.uintItems.setItem(
            5,
            "acceptablePrice",
            order.acceptablePrice()
        );
        eventData.uintItems.setItem(6, "executionFee", order.executionFee());
        eventData.uintItems.setItem(
            7,
            "callbackGasLimit",
            order.callbackGasLimit()
        );
        eventData.uintItems.setItem(
            8,
            "minOutputAmount",
            order.minOutputAmount()
        );
        eventData.uintItems.setItem(
            9,
            "updatedAtBlock",
            order.updatedAtBlock()
        );

        eventData.boolItems.initItems(3);
        eventData.boolItems.setItem(0, "isLong", order.isLong());
        eventData.boolItems.setItem(
            1,
            "shouldUnwrapNativeToken",
            order.shouldUnwrapNativeToken()
        );
        eventData.boolItems.setItem(2, "isFrozen", order.isFrozen());

        eventData.bytes32Items.initItems(1);
        eventData.bytes32Items.setItem(0, "key", key);

        // eventData.bytesItems.initItems(1);
        // eventData.bytesItems.setItem(
        //     0,
        //     "reasonBytes",
        //     oldEventData.bytesItems.items[0].value
        // );

        // eventData.stringItems.initItems(1);
        // eventData.stringItems.setItem(
        //     0,
        //     "reason",
        //     oldEventData.stringItems.items[0].value
        // );

        _emitEventLog2(
            ORDER_CANCELLED_EVENT_NAME,
            key,
            Cast.toBytes32(order.account()),
            eventData
        );
    }

    // @dev called after an order has been frozen, see OrderUtils.freezeOrder in OrderHandler for more info
    // @param key the key of the order
    // @param order the order that was frozen
    function afterOrderFrozen(
        bytes32 key,
        Order.Props memory order,
        EventUtils.EventLogData memory eventData
    ) external view override onlyController {
        key;
        order;
        eventData;
    }
}
