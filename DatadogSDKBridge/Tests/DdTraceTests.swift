/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSDKBridge
@testable import Datadog

internal class DdTraceTests: XCTestCase {
    private let mockNativeTracer = MockTracer()
    private var tracer: DdTraceImpementation! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUpWithError() throws {
        try super.setUpWithError()
        tracer = DdTraceImpementation { self.mockNativeTracer }
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
            timestampMs: Int64(timestampInMiliseconds),
            context: testTags
        )

        XCTAssertNotNil(spanID)
        XCTAssertEqual(mockNativeTracer.startedSpans.count, 1)
        let startedSpan = try XCTUnwrap(mockNativeTracer.startedSpans.first)
        XCTAssertEqual(startedSpan.name, "test_span")
        XCTAssertNil(startedSpan.parent)
        let startDate = Date(timeIntervalSince1970: Date.timeIntervalBetween1970AndReferenceDate)
        XCTAssertEqual(startedSpan.startTime, startDate)
        let tags = try XCTUnwrap(startedSpan.tags as? [String: AnyEncodable])
        XCTAssertEqual(tags["key_string"]?.value as? String, "value")
        XCTAssertEqual(tags["key_number"]?.value as? Int, 123)
        XCTAssertEqual(tags["key_bool"]?.value as? Bool, true)
    }

    func testFinishingASpan() throws {
        let startDate = Date(timeIntervalSinceReferenceDate: 0.0)
        let timestampMs = Int64(startDate.timeIntervalSince1970 * 1_000)
        let spanID = tracer.startSpan(
            operation: "test_span",
            timestampMs: timestampMs,
            context: testTags
        )

        XCTAssertEqual(Array(tracer.spanDictionary.keys), [spanID])
        let startedSpan = try XCTUnwrap(mockNativeTracer.startedSpans.last)
        XCTAssertEqual(startedSpan.finishTime, MockSpan.unfinished)

        let spanDuration: TimeInterval = 10.0
        let spanDurationMs = Int64(spanDuration) * 1_000
        let finishTimestampMs = timestampMs + spanDurationMs
        let finishingContext = NSDictionary(dictionary: ["last_key": "last_value"])
        tracer.finishSpan(spanId: spanID, timestampMs: finishTimestampMs, context: finishingContext)

        XCTAssertEqual(Array(tracer.spanDictionary.keys), [])
        XCTAssertEqual(startedSpan.finishTime, startDate + spanDuration)
        let tags = try XCTUnwrap(startedSpan.tags as? [String: AnyEncodable])
        XCTAssertEqual(tags["last_key"]?.value as? String, "last_value")
    }

    func testFinishingInexistentSpan() {
        _ = tracer.startSpan(
            operation: "test_span",
            timestampMs: 100,
            context: NSDictionary()
        )

        XCTAssertEqual(tracer.spanDictionary.count, 1)

        XCTAssertNoThrow(
            tracer.finishSpan(
                spanId: "inexistent_test_span_id",
                timestampMs: 0,
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
                timestampMs: 0,
                context: testTags
            )
            tracer.finishSpan(spanId: spanID, timestampMs: 100, context: testTags)
        }

        XCTAssertEqual(mockNativeTracer.startedSpans.count, iterationCount, "\(mockNativeTracer.startedSpans)")
        XCTAssertEqual(tracer.spanDictionary.count, 0)
    }
}

private class MockTracer: OTTracer {
    var activeSpan: OTSpan?

    private(set) var startedSpans = [MockSpan]()
    func startSpan(operationName: String, references: [OTReference]?, tags: [String: Encodable]?, startTime: Date?) -> OTSpan {
        let mockSpan = MockSpan(name: operationName, parent: nil, tags: tags, startTime: startTime)
        startedSpans.append(mockSpan)
        return mockSpan
    }

    // swiftlint:disable unavailable_function
    func inject(spanContext: OTSpanContext, writer: OTFormatWriter) {
        fatalError("Should not be called")
    }
    func extract(reader: OTFormatReader) -> OTSpanContext? {
        fatalError("Should not be called")
    }
    // swiftlint:enable unavailable_function
}

private class MockSpan: OTSpan {
    static let unfinished: Date = .distantFuture

    let name: String
    let parent: OTSpanContext?
    private(set) var tags: [String: Encodable]
    let startTime: Date?
    init(name: String, parent: OTSpanContext?, tags: [String: Encodable]?, startTime: Date?) {
        self.name = name
        self.parent = parent
        self.tags = tags ?? [:]
        self.startTime = startTime
    }

    func setTag(key: String, value: Encodable) {
        tags[key] = value
    }

    private(set) var finishTime: Date? = MockSpan.unfinished
    func finish(at time: Date) {
        self.finishTime = time
    }

    // swiftlint:disable unavailable_function
    var context: OTSpanContext { fatalError("Should not be called") }
    func tracer() -> OTTracer {
        fatalError("Should not be called")
    }
    func setOperationName(_ operationName: String) {
        fatalError("Should not be called")
    }
    func log(fields: [String: Encodable], timestamp: Date) {
        fatalError("Should not be called")
    }
    func setBaggageItem(key: String, value: String) {
        fatalError("Should not be called")
    }
    func baggageItem(withKey key: String) -> String? {
        fatalError("Should not be called")
    }
    func setActive() -> OTSpan {
        fatalError("Should not be called")
    }
    // swiftlint:enable unavailable_function
}
