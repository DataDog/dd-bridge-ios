/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import DatadogObjc

internal class DdTraceImpementation: DdTrace {
    private let tracer: OTTracer
    private(set) var spanDictionary = [NSString: OTSpan]()

    internal init(_ ddTracer: OTTracer) {
        self.tracer = ddTracer
    }

    convenience init() {
        self.init(DDTracer(configuration: DDTracerConfiguration()))
    }

    func startSpan(operation: NSString, timestamp: Int64, context: NSDictionary) -> NSString {
        let id = UUID().uuidString as NSString
        let timeIntervalSince1970: TimeInterval = Double(timestamp) / 1_000
        let startDate = Date(timeIntervalSince1970: timeIntervalSince1970)

        objc_sync_enter(self)
        spanDictionary[id] = tracer.startSpan(
            operation as String,
            childOf: nil,
            tags: context,
            startTime: startDate
        )
        objc_sync_exit(self)

        return id
    }

    func finishSpan(spanId: NSString, timestamp: Int64, context: NSDictionary) {
        objc_sync_enter(self)
        let optionalSpan = spanDictionary.removeValue(forKey: spanId)
        objc_sync_exit(self)

        if let span = optionalSpan {
            set(tags: context, to: span)
            let timestampInSeconds = TimeInterval(timestamp / 1_000)
            span.finishWithTime(Date(timeIntervalSince1970: timestampInSeconds))
        }
    }

    private func set(tags: NSDictionary, to span: OTSpan) {
        guard let stringKeyedTags = tags as? [String: Any] else {
            return
        }
        for (key, value) in stringKeyedTags {
            if let tagNSString = value as? NSString {
                span.setTag(key, value: tagNSString)
            } else if let tagNSNumber = value as? NSNumber {
                span.setTag(key, numberValue: tagNSNumber)
            } else if let tagBool = value as? Bool {
                span.setTag(key, boolValue: tagBool)
            }
        }
    }
}
