/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSDKBridge
@testable import DatadogObjc

internal class DdRumTests: XCTestCase {
    private let mockNativeRUM = MockNativeRUM()
    private var rum: DdRum! // swiftlint:disable:this implicitly_unwrapped_optional

    private let randomTimestamp = Int64.random(in: 0...Int64.max)

    override func setUpWithError() throws {
        try super.setUpWithError()
        rum = DdRumImplementation(mockNativeRUM)
    }

    func testStartView() {
        rum.startView(key: "view key", name: "view name", timestamp: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .startView(key: "view key", path: "view name"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        XCTAssertEqual(mockNativeRUM.receivedAttributes.last, ["foo": 123, DdRumImplementation.timestampKey: randomTimestamp])
    }

    func testStopView() {
        rum.stopView(key: "view key", timestamp: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .stopView(key: "view key"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        XCTAssertEqual(mockNativeRUM.receivedAttributes.last, ["foo": 123, DdRumImplementation.timestampKey: randomTimestamp])
    }

    func testStartAction() {
        rum.startAction(type: "custom", name: "action name", timestamp: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .startUserAction(type: .custom, name: "action name"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        XCTAssertEqual(mockNativeRUM.receivedAttributes.last, ["foo": 123, DdRumImplementation.timestampKey: randomTimestamp])
    }

    func testStopActionWithoutStarting() {
        rum.stopAction(timestamp: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 0)
    }

    func testStopAction() {
        rum.startAction(type: "custom", name: "action name", timestamp: 0, context: [:])
        rum.stopAction(timestamp: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 2)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .stopUserAction(type: .custom, name: "action name"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 2)
        XCTAssertEqual(mockNativeRUM.receivedAttributes.last, ["foo": 123, DdRumImplementation.timestampKey: randomTimestamp])
    }

    func testAddAction() {
        rum.addAction(type: "scroll", name: "action name", timestamp: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .addUserAction(type: .scroll, name: "action name"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        XCTAssertEqual(mockNativeRUM.receivedAttributes.last, ["foo": 123, DdRumImplementation.timestampKey: randomTimestamp])
    }

    func testStartResource() {
        rum.startResource(key: "resource key", method: "put", url: "some/url/string", timestamp: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .startResourceLoading(resourceKey: "resource key", httpMethod: "put", urlString: "some/url/string"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        XCTAssertEqual(mockNativeRUM.receivedAttributes.last, ["foo": 123, DdRumImplementation.timestampKey: randomTimestamp])
    }

    func testStopResource() {
        rum.stopResource(key: "resource key", statusCode: 999, kind: "xhr", timestamp: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .stopResourceLoading(resourceKey: "resource key", statusCode: 999, kind: .xhr))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        XCTAssertEqual(mockNativeRUM.receivedAttributes.last, ["foo": 123, DdRumImplementation.timestampKey: randomTimestamp])
    }

    func testAddError() {
        rum.addError(message: "error message", source: "webview", stacktrace: "error trace", timestamp: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .addError(message: "error message", source: .webview, stack: "error trace"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        XCTAssertEqual(mockNativeRUM.receivedAttributes.last, ["foo": 123, DdRumImplementation.timestampKey: randomTimestamp])
    }
}

private class MockNativeRUM: NativeRUM {
    enum RUMMethod: Equatable {
        case startView(key: String, path: String?)
        case stopView(key: String)
        case addError(message: String, source: DDRUMErrorSource, stack: String?)
        case startResourceLoading(resourceKey: String, httpMethod: String, urlString: String)
        case stopResourceLoading(resourceKey: String, statusCode: Int, kind: DDRUMResourceKind)
        case startUserAction(type: DDRUMUserActionType, name: String)
        case stopUserAction(type: DDRUMUserActionType, name: String?)
        case addUserAction(type: DDRUMUserActionType, name: String)
    }

    private(set) var calledMethods = [RUMMethod]()
    private(set) var receivedAttributes = [[String: Int64]?]()

    func startView(key: String, path: String?, attributes: [String: Any]) {
        calledMethods.append(.startView(key: key, path: path))
        receivedAttributes.append(attributes as? [String: Int64])
    }
    func stopView(key: String, attributes: [String: Any]) {
        calledMethods.append(.stopView(key: key))
        receivedAttributes.append(attributes as? [String: Int64])
    }
    func addError(message: String, source: DDRUMErrorSource, stack: String?, attributes: [String: Any]) {
        calledMethods.append(.addError(message: message, source: source, stack: stack))
        receivedAttributes.append(attributes as? [String: Int64])
    }
    func startResourceLoading(resourceKey: String, httpMethod: String, urlString: String, attributes: [String: Any]) {
        calledMethods.append(.startResourceLoading(resourceKey: resourceKey, httpMethod: httpMethod, urlString: urlString))
        receivedAttributes.append(attributes as? [String: Int64])
    }
    func stopResourceLoading(resourceKey: String, statusCode: Int, kind: DDRUMResourceKind, attributes: [String: Any]) {
        calledMethods.append(.stopResourceLoading(resourceKey: resourceKey, statusCode: statusCode, kind: kind))
        receivedAttributes.append(attributes as? [String: Int64])
    }
    func startUserAction(type: DDRUMUserActionType, name: String, attributes: [String: Any]) {
        calledMethods.append(.startUserAction(type: type, name: name))
        receivedAttributes.append(attributes as? [String: Int64])
    }
    func stopUserAction(type: DDRUMUserActionType, name: String?, attributes: [String: Any]) {
        calledMethods.append(.stopUserAction(type: type, name: name))
        receivedAttributes.append(attributes as? [String: Int64])
    }
    func addUserAction(type: DDRUMUserActionType, name: String, attributes: [String: Any]) {
        calledMethods.append(.addUserAction(type: type, name: name))
        receivedAttributes.append(attributes as? [String: Int64])
    }
}
