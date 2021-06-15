/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSDKBridge

internal class DdLogsTests: XCTestCase {
    private let mockNativeLogger = MockNativeLogger()
    private lazy var logger = DdLogsImplementation { self.mockNativeLogger }

    private let testMessage_swift: String = "message"
    private let testMessage_objc: NSString = "message"
    private let validTestAttributes_swift: [String: Encodable] = ["key1": "value", "key2": 123]
    private let validTestAttributes_objc = NSDictionary(
        dictionary: ["key1": "value", "key2": 123]
    )
    private let invalidTestAttributes = NSDictionary(
        dictionary: ["key1": "value", 123: "value2"]
    )

    func testLoggerDebug_validAttributes() throws {
        logger.debug(message: testMessage_objc, context: validTestAttributes_objc)

        XCTAssertEqual(mockNativeLogger.receivedMethodCalls.count, 1)
        let received = try XCTUnwrap(mockNativeLogger.receivedMethodCalls.first)
        XCTAssertEqual(received.kind, .debug)
        XCTAssertEqual(received.message, testMessage_swift)
        XCTAssertEqual(received.attributes?.keys, validTestAttributes_swift.keys)
    }

    func testLoggerInfo_validAttributes() throws {
        logger.info(message: testMessage_objc, context: validTestAttributes_objc)

        XCTAssertEqual(mockNativeLogger.receivedMethodCalls.count, 1)
        let received = try XCTUnwrap(mockNativeLogger.receivedMethodCalls.first)
        XCTAssertEqual(received.kind, .info)
        XCTAssertEqual(received.message, testMessage_swift)
        XCTAssertEqual(received.attributes?.keys, validTestAttributes_swift.keys)
    }

    func testLoggerWarn_validAttributes() throws {
        logger.warn(message: testMessage_objc, context: validTestAttributes_objc)

        XCTAssertEqual(mockNativeLogger.receivedMethodCalls.count, 1)
        let received = try XCTUnwrap(mockNativeLogger.receivedMethodCalls.first)
        XCTAssertEqual(received.kind, .warn)
        XCTAssertEqual(received.message, testMessage_swift)
        XCTAssertEqual(received.attributes?.keys, validTestAttributes_swift.keys)
    }

    func testLoggerError_validAttributes() throws {
        logger.error(message: testMessage_objc, context: validTestAttributes_objc)

        XCTAssertEqual(mockNativeLogger.receivedMethodCalls.count, 1)
        let received = try XCTUnwrap(mockNativeLogger.receivedMethodCalls.first)
        XCTAssertEqual(received.kind, .error)
        XCTAssertEqual(received.message, testMessage_swift)
        XCTAssertEqual(received.attributes?.keys, validTestAttributes_swift.keys)
    }

    func testLoggerDebug_invalidAttributes() throws {
        logger.debug(message: testMessage_objc, context: invalidTestAttributes)

        XCTAssertEqual(mockNativeLogger.receivedMethodCalls.count, 1)
        let received = try XCTUnwrap(mockNativeLogger.receivedMethodCalls.first)
        XCTAssertEqual(received.kind, .debug)
        XCTAssertEqual(received.message, testMessage_swift)
        XCTAssertEqual(received.attributes?.keys, [:].keys)
    }

    func testLoggerInfo_invalidAttributes() throws {
        logger.info(message: testMessage_objc, context: invalidTestAttributes)

        XCTAssertEqual(mockNativeLogger.receivedMethodCalls.count, 1)
        let received = try XCTUnwrap(mockNativeLogger.receivedMethodCalls.first)
        XCTAssertEqual(received.kind, .info)
        XCTAssertEqual(received.message, testMessage_swift)
        XCTAssertEqual(received.attributes?.keys, [:].keys)
    }

    func testLoggerWarn_invalidAttributes() throws {
        logger.warn(message: testMessage_objc, context: invalidTestAttributes)

        XCTAssertEqual(mockNativeLogger.receivedMethodCalls.count, 1)
        let received = try XCTUnwrap(mockNativeLogger.receivedMethodCalls.first)
        XCTAssertEqual(received.kind, .warn)
        XCTAssertEqual(received.message, testMessage_swift)
        XCTAssertEqual(received.attributes?.keys, [:].keys)
    }

    func testLoggerError_invalidAttributes() throws {
        logger.error(message: testMessage_objc, context: invalidTestAttributes)

        XCTAssertEqual(mockNativeLogger.receivedMethodCalls.count, 1)
        let received = try XCTUnwrap(mockNativeLogger.receivedMethodCalls.first)
        XCTAssertEqual(received.kind, .error)
        XCTAssertEqual(received.message, testMessage_swift)
        XCTAssertEqual(received.attributes?.keys, [:].keys)
    }
}

private class MockNativeLogger: NativeLogger {
    struct MethodCall {
        enum Kind {
            case debug
            case info
            case warn
            case error
        }
        let kind: Kind
        let message: String
        let attributes: [String: Encodable]?
    }
    private(set) var receivedMethodCalls = [MethodCall]()

    func debug(_ message: String, error: Error?, attributes: [String: Encodable]?) {
        receivedMethodCalls.append(MethodCall(kind: .debug, message: message, attributes: attributes))
    }
    func info(_ message: String, error: Error?, attributes: [String: Encodable]?) {
        receivedMethodCalls.append(MethodCall(kind: .info, message: message, attributes: attributes))
    }
    func warn(_ message: String, error: Error?, attributes: [String: Encodable]?) {
        receivedMethodCalls.append(MethodCall(kind: .warn, message: message, attributes: attributes))
    }
    func error(_ message: String, error: Error?, attributes: [String: Encodable]?) {
        receivedMethodCalls.append(MethodCall(kind: .error, message: message, attributes: attributes))
    }
}
