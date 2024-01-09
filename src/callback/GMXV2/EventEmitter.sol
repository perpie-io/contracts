// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
import {EventUtils} from "@gmxv2/event/EventUtils.sol";

/**
 * An internal implementation of the GMXV2 EventEmitter
 */
contract GMXV2EventEmitter {
    event EventLog(
        address msgSender,
        string eventName,
        string indexed eventNameHash,
        EventUtils.EventLogData eventData
    );

    event EventLog1(
        address msgSender,
        string eventName,
        string indexed eventNameHash,
        bytes32 indexed topic1,
        EventUtils.EventLogData eventData
    );

    event EventLog2(
        address msgSender,
        string eventName,
        string indexed eventNameHash,
        bytes32 indexed topic1,
        bytes32 indexed topic2,
        EventUtils.EventLogData eventData
    );

    // @dev emit a general event log
    // @param eventName the name of the event
    // @param eventData the event data
    function _emitEventLog(
        string memory eventName,
        EventUtils.EventLogData memory eventData
    ) internal {
        emit EventLog(msg.sender, eventName, eventName, eventData);
    }

    // @dev emit a general event log
    // @param eventName the name of the event
    // @param topic1 topic1 for indexing
    // @param eventData the event data
    function _emitEventLog1(
        string memory eventName,
        bytes32 topic1,
        EventUtils.EventLogData memory eventData
    ) internal {
        emit EventLog1(msg.sender, eventName, eventName, topic1, eventData);
    }

    // @dev emit a general event log
    // @param eventName the name of the event
    // @param topic1 topic1 for indexing
    // @param topic2 topic2 for indexing
    // @param eventData the event data
    function _emitEventLog2(
        string memory eventName,
        bytes32 topic1,
        bytes32 topic2,
        EventUtils.EventLogData memory eventData
    ) internal {
        emit EventLog2(
            msg.sender,
            eventName,
            eventName,
            topic1,
            topic2,
            eventData
        );
    }

    // @dev event log for general use
    // @param topic1 event topic 1
    // @param data additional data
    function _emitDataLog1(bytes32 topic1, bytes memory data) internal {
        uint256 len = data.length;
        assembly {
            log1(add(data, 32), len, topic1)
        }
    }

    // @dev event log for general use
    // @param topic1 event topic 1
    // @param topic2 event topic 2
    // @param data additional data
    function _emitDataLog2(
        bytes32 topic1,
        bytes32 topic2,
        bytes memory data
    ) internal {
        uint256 len = data.length;
        assembly {
            log2(add(data, 32), len, topic1, topic2)
        }
    }

    // @dev event log for general use
    // @param topic1 event topic 1
    // @param topic2 event topic 2
    // @param topic3 event topic 3
    // @param data additional data
    function _emitDataLog3(
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes memory data
    ) internal {
        uint256 len = data.length;
        assembly {
            log3(add(data, 32), len, topic1, topic2, topic3)
        }
    }

    // @dev event log for general use
    // @param topic1 event topic 1
    // @param topic2 event topic 2
    // @param topic3 event topic 3
    // @param topic4 event topic 4
    // @param data additional data
    function _emitDataLog4(
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes32 topic4,
        bytes memory data
    ) internal {
        uint256 len = data.length;
        assembly {
            log4(add(data, 32), len, topic1, topic2, topic3, topic4)
        }
    }
}
