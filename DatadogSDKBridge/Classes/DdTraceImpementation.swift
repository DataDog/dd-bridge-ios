/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import DatadogObjc

internal class DdTraceImpementation: DdTrace {
    private lazy var tracer: OTTracer = {
        return DDTracer.initialize(configuration: DDTracerConfiguration())
    }()
    private var spanDictionary = [NSString: OTSpan]()

    func startSpan(operation: NSString, timestamp: Int64, context: NSDictionary) -> NSString {
        let id = UUID().uuidString as NSString
        spanDictionary[id] = tracer.startSpan(operation as String, tags: context)
        return id
    }

    func finishSpan(spanId: NSString, timestamp: Int64, context: NSDictionary) {
        if let span = spanDictionary[spanId] {
            let timestampInSeconds = TimeInterval(timestamp / 1_000)
            span.finishWithTime(Date(timeIntervalSince1970: timestampInSeconds))

            spanDictionary[spanId] = nil
        }
    }
}
