/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import Datadog

extension DDRUMMonitor: NativeRUM { }
internal protocol NativeRUM {
    func startView(key: String, path: String?, attributes: [String: Encodable])
    func stopView(key: String, attributes: [String: Encodable])
    func addError(message: String, source: RUMErrorSource, stack: String?, attributes: [String: Encodable], file: StaticString?, line: UInt?)
    func startResourceLoading(resourceKey: String, httpMethod: RUMMethod, urlString: String, attributes: [String: Encodable])
    func stopResourceLoading(resourceKey: String, statusCode: Int?, kind: RUMResourceType, size: Int64?, attributes: [String: Encodable])
    func startUserAction(type: RUMUserActionType, name: String, attributes: [String: Encodable])
    func stopUserAction(type: RUMUserActionType, name: String?, attributes: [String: Encodable])
    func addUserAction(type: RUMUserActionType, name: String, attributes: [String: Encodable])
}

private extension RUMUserActionType {
    init(from string: String) {
        switch string.lowercased() {
        case "tap": self = .tap
        case "scroll": self = .scroll
        case "swipe": self = .swipe
        default: self = .custom
        }
    }
}

private extension RUMErrorSource {
    init(from string: String) {
        switch string.lowercased() {
        case "source": self = .source
        case "network": self = .network
        case "webview": self = .webview
        default: self = .custom
        }
    }
}

private extension RUMResourceType {
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

private extension RUMMethod {
    init(from string: String) {
        switch string.uppercased() {
        case "POST": self = .post
        case "GET": self = .get
        case "HEAD": self = .head
        case "PUT": self = .put
        case "DELETE": self = .delete
        case "PATCH": self = .patch
        default: self = .get
        }
    }
}

internal class DdRumImplementation: DdRum {
    internal static let timestampKey = "_dd.timestamp"

    let nativeRUM: NativeRUM

    private typealias UserAction = (type: RUMUserActionType, name: String?)
    private var ongoingUserActions = [UserAction]()

    internal init(_ nativeRUM: NativeRUM) {
        self.nativeRUM = nativeRUM
    }

    convenience init() {
        self.init(RUMMonitor.initialize())
    }

    func startView(key: NSString, name: NSString, timestampMs: Int64, context: NSDictionary) {
        nativeRUM.startView(key: key as String, path: name as String, attributes: attributes(from: context, with: timestampMs))
    }

    func stopView(key: NSString, timestampMs: Int64, context: NSDictionary) {
        nativeRUM.stopView(key: key as String, attributes: attributes(from: context, with: timestampMs))
    }

    func startAction(type: NSString, name: NSString, timestampMs: Int64, context: NSDictionary) {
        let actionType = RUMUserActionType(from: type as String)
        nativeRUM.startUserAction(type: actionType, name: name as String, attributes: attributes(from: context, with: timestampMs))
        ongoingUserActions.append((type: actionType, name: name as String))
    }

    func stopAction(timestampMs: Int64, context: NSDictionary) {
        guard let userAction = ongoingUserActions.popLast() else {
            return
        }
        nativeRUM.stopUserAction(type: userAction.type, name: userAction.name, attributes: attributes(from: context, with: timestampMs))
    }

    func addAction(type: NSString, name: NSString, timestampMs: Int64, context: NSDictionary) {
        nativeRUM.addUserAction(type: RUMUserActionType(from: type as String), name: name as String, attributes: attributes(from: context, with: timestampMs))
    }

    func startResource(key: NSString, method: NSString, url: NSString, timestampMs: Int64, context: NSDictionary) {
        nativeRUM.startResourceLoading(resourceKey: key as String, httpMethod: RUMMethod(from: method as String), urlString: url as String, attributes: attributes(from: context, with: timestampMs))
    }

    func stopResource(key: NSString, statusCode: Int64, kind: NSString, timestampMs: Int64, context: NSDictionary) {
        nativeRUM.stopResourceLoading(resourceKey: key as String, statusCode: Int(statusCode), kind: RUMResourceType(from: kind as String), size: nil, attributes: attributes(from: context, with: timestampMs))
    }

    func addError(message: NSString, source: NSString, stacktrace: NSString, timestampMs: Int64, context: NSDictionary) {
        nativeRUM.addError(message: message as String, source: RUMErrorSource(from: source as String), stack: stacktrace as String, attributes: attributes(from: context, with: timestampMs), file: nil, line: nil)
    }

    // MARK: - Private methods

    private func attributes(from context: NSDictionary, with timestampMs: Int64) -> [String: Encodable] {
        var context = context as? [String: Any] ?? [:]
        context[Self.timestampKey] = timestampMs
        return castAttributesToSwift(context)
    }
}
