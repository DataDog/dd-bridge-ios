/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSDKBridge
@testable import DatadogObjc

internal class DdTraceTests: XCTestCase {
    private let mockNativeTracer = MockTracer()
    private var tracer: DdTraceImpementation! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUpWithError() throws {
        try super.setUpWithError()
        tracer = DdTraceImpementation(mockNativeTracer)
    }

    private let testTags = NSDictionary(
        dictionary: [
            "key_string": NSString("value"),
            "key_number": (123 as NSNumber),
            "key_bool": true
        ]
    )

    func testStartingASpan() throws {
        let timestampInMiliseconds = Date.timeIntervalBetween1970AndReferenceDate * 1_000
        let spanID = tracer.startSpan(
            operation: "test_span",
            timestamp: Int64(timestampInMiliseconds),
            context: testTags
        )

        XCTAssertNotNil(spanID)
        XCTAssertEqual(mockNativeTracer.startedSpans.count, 1)
        let startedSpan = try XCTUnwrap(mockNativeTracer.startedSpans.first)
        XCTAssertEqual(startedSpan.name, "test_span")
        XCTAssertNil(startedSpan.parent)
        let startDate = Date(timeIntervalSince1970: Date.timeIntervalBetween1970AndReferenceDate)
        XCTAssertEqual(startedSpan.tags, testTags)
        XCTAssertEqual(startedSpan.startTime, startDate)
    }

    func testFinishingASpan() throws {
        let startDate = Date(timeIntervalSinceReferenceDate: 0.0)
        let timestampInMiliseconds = Int64(startDate.timeIntervalSince1970 * 1_000)
        let spanID = tracer.startSpan(
            operation: "test_span",
            timestamp: timestampInMiliseconds,
            context: testTags
        )

        XCTAssertEqual(Array(tracer.spanDictionary.keys), [spanID])
        let startedSpan = try XCTUnwrap(mockNativeTracer.startedSpans.last)
        XCTAssertEqual(startedSpan.finishTime, MockSpan.unfinished)

        let spanDuration: TimeInterval = 10.0
        let spanDurationInMiliseconds = Int64(spanDuration) * 1_000
        let finishTimestampInMiliseconds = timestampInMiliseconds + spanDurationInMiliseconds
        let finishingContext = NSDictionary(dictionary: ["last_key": "last_value"])
        tracer.finishSpan(spanId: spanID, timestamp: finishTimestampInMiliseconds, context: finishingContext)

        XCTAssertEqual(Array(tracer.spanDictionary.keys), [])
        XCTAssertEqual(startedSpan.finishTime, startDate + spanDuration)
        XCTAssertEqual(startedSpan.tags?["last_key"] as? String, "last_value")
    }

    func testFinishingInexistentSpan() {
        _ = tracer.startSpan(
            operation: "test_span",
            timestamp: 100,
            context: NSDictionary()
        )

        XCTAssertEqual(tracer.spanDictionary.count, 1)

        XCTAssertNoThrow(
            tracer.finishSpan(
                spanId: "inexistent_test_span_id",
                timestamp: 0,
                context: NSDictionary()
            )
        )

        XCTAssertEqual(tracer.spanDictionary.count, 1)
    }

    func testTracingConcurrently() {
        let iterationCount = 30
        DispatchQueue.concurrentPerform(iterations: iterationCount) { iteration in
            let spanID = tracer.startSpan(
                operation: "concurrent_test_span_\(iteration)" as NSString,
                timestamp: 0,
                context: testTags
            )
            tracer.finishSpan(spanId: spanID, timestamp: 100, context: testTags)
        }

        XCTAssertEqual(mockNativeTracer.startedSpans.count, iterationCount, "\(mockNativeTracer.startedSpans)")
        XCTAssertEqual(tracer.spanDictionary.count, 0)
    }
}

private class MockTracer: OTTracer {
    private(set) var startedSpans = [MockSpan]()
    func startSpan(_ operationName: String, childOf parent: OTSpanContext?, tags: NSDictionary?, startTime: Date?) -> OTSpan {
        let mockSpan = MockSpan(name: operationName, parent: parent, tags: tags, startTime: startTime)
        startedSpans.append(mockSpan)
        return mockSpan
    }

    // swiftlint:disable unavailable_function
    func startSpan(_ operationName: String) -> OTSpan {
        fatalError("Should not be called")
    }
    func startSpan(_ operationName: String, tags: NSDictionary?) -> OTSpan {
        fatalError("Should not be called")
    }
    func startSpan(_ operationName: String, childOf parent: OTSpanContext?) -> OTSpan {
        fatalError("Should not be called")
    }
    func startSpan(_ operationName: String, childOf parent: OTSpanContext?, tags: NSDictionary?) -> OTSpan {
        fatalError("Should not be called")
    }
    func inject(_ spanContext: OTSpanContext, format: String, carrier: Any) throws {
        fatalError("Should not be called")
    }
    func extractWithFormat(_ format: String, carrier: Any) throws {
        fatalError("Should not be called")
    }
    // swiftlint:enable unavailable_function
}

private class MockSpan: OTSpan {
    static let unfinished: Date = .distantFuture

    let name: String
    let parent: OTSpanContext?
    private(set) var tags: NSMutableDictionary?
    let startTime: Date?
    init(name: String, parent: OTSpanContext?, tags: NSDictionary?, startTime: Date?) {
        self.name = name
        self.parent = parent
        self.tags = tags.flatMap { NSMutableDictionary(dictionary: $0) }
        self.startTime = startTime
    }

    func setTag(_ key: String, value: NSString) {
        tags?.setObject(value, forKey: key as NSString)
    }
    func setTag(_ key: String, numberValue: NSNumber) {
        tags?.setObject(numberValue, forKey: key as NSString)
    }
    func setTag(_ key: String, boolValue: Bool) {
        tags?.setObject(boolValue, forKey: key as NSString)
    }

    private(set) var finishTime: Date? = MockSpan.unfinished
    func finishWithTime(_ finishTime: Date?) {
        self.finishTime = finishTime
    }

    // swiftlint:disable unavailable_function
    var context: OTSpanContext { fatalError("Should not be called") }
    var tracer: OTTracer { fatalError("Should not be called") }
    func setOperationName(_ operationName: String) {
        fatalError("Should not be called")
    }
    func log(_ fields: [String: NSObject]) {
        fatalError("Should not be called")
    }
    func log(_ fields: [String: NSObject], timestamp: Date?) {
        fatalError("Should not be called")
    }
    func setBaggageItem(_ key: String, value: String) -> OTSpan {
        fatalError("Should not be called")
    }
    func getBaggageItem(_ key: String) -> String? {
        fatalError("Should not be called")
    }
    func finish() {
        fatalError("Should not be called")
    }
    // swiftlint:enable unavailable_function
}
