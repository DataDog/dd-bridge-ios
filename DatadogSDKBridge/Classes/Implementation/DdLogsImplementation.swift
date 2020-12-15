/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import DatadogObjc

extension DDLogger: NativeLogger { }
internal protocol NativeLogger {
    func debug(_ message: String, attributes: [String: Any])
    func info(_ message: String, attributes: [String: Any])
    func warn(_ message: String, attributes: [String: Any])
    func error(_ message: String, attributes: [String: Any])
}

public class DdLogsImplementation: DdLogs {
    private let logger: NativeLogger

    internal init(_ ddLogger: NativeLogger) {
        self.logger = ddLogger
    }

    public convenience init() {
        let builder = DDLogger.builder()
        builder.sendNetworkInfo(true)
        builder.printLogsToConsole(true)
        self.init(builder.build())
    }

    public func debug(message: NSString, context: NSDictionary) {
        logger.debug(message as String, attributes: context as? [String: Any] ?? [:])
    }

    public func info(message: NSString, context: NSDictionary) {
        logger.info(message as String, attributes: context as? [String: Any] ?? [:])
    }

    public func warn(message: NSString, context: NSDictionary) {
        logger.warn(message as String, attributes: context as? [String: Any] ?? [:])
    }

    public func error(message: NSString, context: NSDictionary) {
        logger.error(message as String, attributes: context as? [String: Any] ?? [:])
    }
}
