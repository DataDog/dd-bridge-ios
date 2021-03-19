/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSDKBridge
@testable import Datadog

internal class DdRumTests: XCTestCase {
    private let mockNativeRUM = MockNativeRUM()
    private var rum: DdRum! // swiftlint:disable:this implicitly_unwrapped_optional

    private let randomTimestamp = Int64.random(in: 0...Int64.max)

    override func setUpWithError() throws {
        try super.setUpWithError()
        rum = DdRumImplementation(mockNativeRUM)
    }

    func testInternalTimestampKeyValue() {
        XCTAssertEqual(DdRumImplementation.timestampKey, RUMAttribute.internalTimestamp)
    }

    func testStartView() throws {
        rum.startView(key: "view key", name: "view name", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .startView(key: "view key", path: "view name"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = mockNativeRUM.receivedAttributes.last!!
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testStopView() {
        rum.stopView(key: "view key", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .stopView(key: "view key"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = mockNativeRUM.receivedAttributes.last!!
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testStartAction() {
        rum.startAction(type: "custom", name: "action name", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .startUserAction(type: .custom, name: "action name"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = mockNativeRUM.receivedAttributes.last!!
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testStopActionWithoutStarting() {
        rum.stopAction(timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 0)
    }

    func testStopAction() {
        rum.startAction(type: "custom", name: "action name", timestampMs: 0, context: [:])
        rum.stopAction(timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 2)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .stopUserAction(type: .custom, name: "action name"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 2)
        let lastAttribtutes = mockNativeRUM.receivedAttributes.last!!
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testAddAction() {
        rum.addAction(type: "scroll", name: "action name", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .addUserAction(type: .scroll, name: "action name"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = mockNativeRUM.receivedAttributes.last!!
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testStartResource() {
        rum.startResource(key: "resource key", method: "put", url: "some/url/string", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .startResourceLoading(resourceKey: "resource key", httpMethod: .put, urlString: "some/url/string"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = mockNativeRUM.receivedAttributes.last!!
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testStopResource() {
        rum.stopResource(key: "resource key", statusCode: 999, kind: "xhr", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .stopResourceLoading(resourceKey: "resource key", statusCode: 999, kind: .xhr))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = mockNativeRUM.receivedAttributes.last!!
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }

    func testAddError() {
        rum.addError(message: "error message", source: "webview", stacktrace: "error trace", timestampMs: randomTimestamp, context: ["foo": 123])

        XCTAssertEqual(mockNativeRUM.calledMethods.count, 1)
        XCTAssertEqual(mockNativeRUM.calledMethods.last, .addError(message: "error message", source: .webview, stack: "error trace"))
        XCTAssertEqual(mockNativeRUM.receivedAttributes.count, 1)
        let lastAttribtutes = mockNativeRUM.receivedAttributes.last!!
        XCTAssertEqual(lastAttribtutes.count, 2)
        XCTAssertEqual((lastAttribtutes["foo"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual(lastAttribtutes[DdRumImplementation.timestampKey] as? Int64, randomTimestamp)
    }
}

private class MockNativeRUM: NativeRUM {
    
    
    enum CalledMethod: Equatable {
        case startView(key: String, path: String?)
        case stopView(key: String)
        case addError(message: String, source: RUMErrorSource, stack: String?)
        case startResourceLoading(resourceKey: String, httpMethod: RUMMethod, urlString: String)
        case stopResourceLoading(resourceKey: String, statusCode: Int, kind: RUMResourceType)
        case startUserAction(type: RUMUserActionType, name: String)
        case stopUserAction(type: RUMUserActionType, name: String?)
        case addUserAction(type: RUMUserActionType, name: String)
    }

    private(set) var calledMethods = [CalledMethod]()
    private(set) var receivedAttributes = [[String: Encodable]?]()

    func startView(key: String, path: String?, attributes: [String : Encodable]) {
        calledMethods.append(.startView(key: key, path: path))
        receivedAttributes.append(attributes)
    }
    func stopView(key: String, attributes: [String : Encodable]) {
        calledMethods.append(.stopView(key: key))
        receivedAttributes.append(attributes)
    }
    func addError(message: String, source: RUMErrorSource, stack: String?, attributes: [String : Encodable], file: StaticString?, line: UInt?) {
        calledMethods.append(.addError(message: message, source: source, stack: stack))
        receivedAttributes.append(attributes)
    }
    
    func startResourceLoading(resourceKey: String, httpMethod: RUMMethod, urlString: String, attributes: [String : Encodable]) {
        calledMethods.append(.startResourceLoading(resourceKey: resourceKey, httpMethod: httpMethod, urlString: urlString))
        receivedAttributes.append(attributes)
    }
    func stopResourceLoading(resourceKey: String, statusCode: Int?, kind: RUMResourceType, size: Int64?, attributes: [String : Encodable]) {
        calledMethods.append(.stopResourceLoading(resourceKey: resourceKey, statusCode: statusCode ?? 0, kind: kind))
        receivedAttributes.append(attributes)
    }
    func startUserAction(type: RUMUserActionType, name: String, attributes: [String : Encodable]) {
        calledMethods.append(.startUserAction(type: type, name: name))
        receivedAttributes.append(attributes)
    }
    func stopUserAction(type: RUMUserActionType, name: String?, attributes: [String : Encodable]) {
        calledMethods.append(.stopUserAction(type: type, name: name))
        receivedAttributes.append(attributes)
    }
    func addUserAction(type: RUMUserActionType, name: String, attributes: [String : Encodable]) {
        calledMethods.append(.addUserAction(type: type, name: name))
        receivedAttributes.append(attributes)
    }
}
