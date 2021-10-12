/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import Datadog

internal class DdTraceImpementation: DdTrace {
    private lazy var tracer: OTTracer = tracerProvider()
    private let tracerProvider: () -> OTTracer
    private(set) var spanDictionary = [NSString: OTSpan]()

    internal init(_ tracerProvider: @escaping () -> OTTracer) {
        self.tracerProvider = tracerProvider
    }

    convenience init() {
        self.init { Tracer.initialize(configuration: Tracer.Configuration()) }
    }

    func startSpan(operation: NSString, context: NSDictionary, timestampMs: Int64) -> NSString {
        let id = UUID().uuidString as NSString
        let timeIntervalSince1970: TimeInterval = Double(timestampMs) / 1_000
        let startDate = Date(timeIntervalSince1970: timeIntervalSince1970)

        objc_sync_enter(self)
        spanDictionary[id] = tracer.startSpan(
            operationName: operation as String,
            childOf: nil,
            tags: castAttributesToSwift(context).mergeWithGlobalAttributes(),
            startTime: startDate
        )
        objc_sync_exit(self)

        return id
    }

    func finishSpan(spanId: NSString, context: NSDictionary, timestampMs: Int64) {
        objc_sync_enter(self)
        let optionalSpan = spanDictionary.removeValue(forKey: spanId)
        objc_sync_exit(self)

        if let span = optionalSpan {
            set(tags: castAttributesToSwift(context).mergeWithGlobalAttributes(), to: span)
            let timeIntervalSince1970: TimeInterval = Double(timestampMs) / 1_000
            span.finish(at: Date(timeIntervalSince1970: timeIntervalSince1970))
        }
    }

    private func set(tags: [String: Encodable], to span: OTSpan) {
        for (key, value) in tags {
            span.setTag(key: key, value: value)
        }
    }
}
