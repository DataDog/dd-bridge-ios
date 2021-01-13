/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import DatadogObjc

extension DDRUMMonitor: NativeRUM { }
internal protocol NativeRUM {
    func startView(key: String, path: String?, attributes: [String: Any])
    func stopView(key: String, attributes: [String: Any])
    func addError(message: String, source: DDRUMErrorSource, stack: String?, attributes: [String: Any])
    func startResourceLoading(resourceKey: String, httpMethod: String, urlString: String, attributes: [String: Any])
    func stopResourceLoading(resourceKey: String, statusCode: Int, kind: DDRUMResourceKind, attributes: [String: Any])
    func startUserAction(type: DDRUMUserActionType, name: String, attributes: [String: Any])
    func stopUserAction(type: DDRUMUserActionType, name: String?, attributes: [String: Any])
    func addUserAction(type: DDRUMUserActionType, name: String, attributes: [String: Any])
}

private extension DDRUMUserActionType {
    init(from string: String) {
        switch string.lowercased() {
        case "tap": self = .tap
        case "scroll": self = .scroll
        case "swipe": self = .swipe
        default: self = .custom
        }
    }
}

private extension DDRUMErrorSource {
    init(from string: String) {
        switch string.lowercased() {
        case "source": self = .source
        case "network": self = .network
        case "webview": self = .webview
        default: self = .custom
        }
    }
}

private extension DDRUMResourceKind {
    init(from string: String) {
        switch string {
        case "image": self = .image
        case "xhr": self = .xhr
        case "beacon": self = .beacon
        case "css": self = .css
        case "document": self = .document
        case "fetch": self = .fetch
        case "font": self = .font
        case "js": self = .js
        case "media": self = .media
        default: self = .other
        }
    }
}

internal class DdRumImplementation: DdRum {
    internal static let timestampKey = "_dd.timestamp"

    let nativeRUM: NativeRUM

    private typealias UserAction = (type: DDRUMUserActionType, name: String?)
    private var ongoingUserActions = [UserAction]()

    internal init(_ nativeRUM: NativeRUM) {
        self.nativeRUM = nativeRUM
    }

    convenience init() {
        self.init(DDRUMMonitor())
    }

    func startView(key: NSString, name: NSString, timestamp: Int64, context: NSDictionary) {
        nativeRUM.startView(key: key as String, path: name as String, attributes: attributes(from: context, with: timestamp))
    }

    func stopView(key: NSString, timestamp: Int64, context: NSDictionary) {
        nativeRUM.stopView(key: key as String, attributes: attributes(from: context, with: timestamp))
    }

    func startAction(type: NSString, name: NSString, timestamp: Int64, context: NSDictionary) {
        let actionType = DDRUMUserActionType(from: type as String)
        nativeRUM.startUserAction(type: actionType, name: name as String, attributes: attributes(from: context, with: timestamp))
        ongoingUserActions.append((type: actionType, name: name as String))
    }

    func stopAction(timestamp: Int64, context: NSDictionary) {
        guard let userAction = ongoingUserActions.popLast() else {
            return
        }
        nativeRUM.stopUserAction(type: userAction.type, name: userAction.name, attributes: attributes(from: context, with: timestamp))
    }

    func addAction(type: NSString, name: NSString, timestamp: Int64, context: NSDictionary) {
        nativeRUM.addUserAction(type: DDRUMUserActionType(from: type as String), name: name as String, attributes: attributes(from: context, with: timestamp))
    }

    func startResource(key: NSString, method: NSString, url: NSString, timestamp: Int64, context: NSDictionary) {
        nativeRUM.startResourceLoading(resourceKey: key as String, httpMethod: method as String, urlString: url as String, attributes: attributes(from: context, with: timestamp))
    }

    func stopResource(key: NSString, statusCode: Int64, kind: NSString, timestamp: Int64, context: NSDictionary) {
        nativeRUM.stopResourceLoading(resourceKey: key as String, statusCode: Int(statusCode), kind: DDRUMResourceKind(from: kind as String), attributes: attributes(from: context, with: timestamp))
    }

    func addError(message: NSString, source: NSString, stacktrace: NSString, timestamp: Int64, context: NSDictionary) {
        nativeRUM.addError(message: message as String, source: DDRUMErrorSource(from: source as String), stack: stacktrace as String, attributes: attributes(from: context, with: timestamp))
    }

    // MARK: - Private methods

    private func attributes(from context: NSDictionary, with timestamp: Int64) -> [String: Any] {
        var attributes = context as? [String: Any] ?? [:]
        attributes[Self.timestampKey] = timestamp
        return attributes
    }
}
