/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2016-Present Datadog, Inc.
 */

import Foundation

/**
   The entry point to use Datadog's RUM feature.
 */
@objc(DdRum)
public protocol DdRum {
    /**
       Start tracking a RUM View.
     */
    func startView(key: NSString, name: NSString, context: NSDictionary, timestampMs: Int64)

    /**
       Stop tracking a RUM View.
     */
    func stopView(key: NSString, context: NSDictionary, timestampMs: Int64)

    /**
       Start tracking a RUM Action.
     */
    func startAction(type: NSString, name: NSString, context: NSDictionary, timestampMs: Int64)

    /**
       Stop tracking the ongoing RUM Action.
     */
    func stopAction(context: NSDictionary, timestampMs: Int64)

    /**
       Add a RUM Action.
     */
    func addAction(type: NSString, name: NSString, context: NSDictionary, timestampMs: Int64)

    /**
       Start tracking a RUM Resource.
     */
    func startResource(key: NSString, method: NSString, url: NSString, context: NSDictionary, timestampMs: Int64)

    /**
       Stop tracking a RUM Resource.
     */
    func stopResource(key: NSString, statusCode: Int64, kind: NSString, size: Int64, context: NSDictionary, timestampMs: Int64)

    /**
       Add a RUM Error.
     */
    func addError(message: NSString, source: NSString, stacktrace: NSString, context: NSDictionary, timestampMs: Int64)

    /**
       Adds a specific timing in the active View. The timing duration will be computed as the difference between the time the View was started and the time this function was called.
     */
    func addTiming(name: NSString)
}
