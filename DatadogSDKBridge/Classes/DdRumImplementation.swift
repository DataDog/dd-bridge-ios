/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

// TODO: RUMM-917 to implement RUM for ObjC

internal class DdRumImplementation: DdRum {
    func startView(key: NSString, name: NSString, timestamp: Int64, context: NSDictionary) {
        print("DdRumImplementation.startView")
    }

    func stopView(key: NSString, timestamp: Int64, context: NSDictionary) {
        print("DdRumImplementation.stopView")
    }

    func startAction(type: NSString, name: NSString, timestamp: Int64, context: NSDictionary) {
        print("DdRumImplementation.startAction")
    }

    func stopAction(timestamp: Int64, context: NSDictionary) {
        print("DdRumImplementation.stopAction")
    }

    func addAction(type: NSString, name: NSString, timestamp: Int64, context: NSDictionary) {
        print("DdRumImplementation.addAction")
    }

    func startResource(key: NSString, method: NSString, url: NSString, timestamp: Int64, context: NSDictionary) {
        print("DdRumImplementation.startResource")
    }

    func stopResource(key: NSString, statusCode: Int64, kind: NSString, timestamp: Int64, context: NSDictionary) {
        print("DdRumImplementation.stopResource")
    }

    func addError(message: NSString, source: NSString, stacktrace: NSString, timestamp: Int64, context: NSDictionary) {
        print("DdRumImplementation.addError")
    }
}
