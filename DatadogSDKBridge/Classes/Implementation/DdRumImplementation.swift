/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import Datadog

extension DDRUMMonitor: NativeRUM { }
internal protocol NativeRUM {
    func startView(key: String, name: String?, attributes: [String: Encodable])
    func stopView(key: String, attributes: [String: Encodable])
    func addError(message: String, source: RUMErrorSource, stack: String?, attributes: [String: Encodable], file: StaticString?, line: UInt?)
    func startResourceLoading(resourceKey: String, httpMethod: RUMMethod, urlString: String, attributes: [String: Encodable])
    func stopResourceLoading(resourceKey: String, statusCode: Int?, kind: RUMResourceType, size: Int64?, attributes: [String: Encodable])
    func startUserAction(type: RUMUserActionType, name: String, attributes: [String: Encodable])
    func stopUserAction(type: RUMUserActionType, name: String?, attributes: [String: Encodable])
    func addUserAction(type: RUMUserActionType, name: String, attributes: [String: Encodable])
    func addTiming(name: String)
    func addResourceMetrics(resourceKey: String,
                            fetch: (start: Date, end: Date),
                            redirection: (start: Date, end: Date)?,
                            dns: (start: Date, end: Date)?,
                            connect: (start: Date, end: Date)?,
                            ssl: (start: Date, end: Date)?,
                            firstByte: (start: Date, end: Date)?,
                            download: (start: Date, end: Date)?,
                            responseSize: Int64?,
                            attributes: [AttributeKey: AttributeValue])
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

internal extension RUMErrorSource {
    init(from string: String) {
        switch string.lowercased() {
        case "source": self = .source
        case "network": self = .network
        case "webview": self = .webview
        case "console": self = .console
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
    internal static let resourceTimingsKey = "_dd.resource_timings"

    internal static let fetchTimingKey = "fetch"
    internal static let redirectTimingKey = "redirect"
    internal static let dnsTimingKey = "dns"
    internal static let connectTimingKey = "connect"
    internal static let sslTimingKey = "ssl"
    internal static let firstByteTimingKey = "firstByte"
    internal static let downloadTimingKey = "download"

    lazy var nativeRUM: NativeRUM = rumProvider()
    private let rumProvider: () -> NativeRUM

    private typealias UserAction = (type: RUMUserActionType, name: String?)
    private var ongoingUserActions = [UserAction]()

    internal init(_ rumProvider: @escaping () -> NativeRUM) {
        self.rumProvider = rumProvider
    }

    convenience init() {
        self.init { Global.rum }
    }

    func startView(key: NSString, name: NSString, timestampMs: Int64, context: NSDictionary) {
        nativeRUM.startView(key: key as String, name: name as String, attributes: attributes(from: context, with: timestampMs))
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
        let mutableContext = NSMutableDictionary(dictionary: context)
        if let resourceTimings = mutableContext.object(forKey: Self.resourceTimingsKey) as? [String: Any] {
            mutableContext.removeObject(forKey: Self.resourceTimingsKey)

            addResourceMetrics(key: key, resourceTimings: resourceTimings)
        }

        nativeRUM.stopResourceLoading(
            resourceKey: key as String,
            statusCode: Int(statusCode),
            kind: RUMResourceType(from: kind as String),
            size: nil,
            attributes: attributes(from: mutableContext, with: timestampMs)
        )
    }

    func addError(message: NSString, source: NSString, stacktrace: NSString, timestampMs: Int64, context: NSDictionary) {
        nativeRUM.addError(message: message as String, source: RUMErrorSource(from: source as String), stack: stacktrace as String, attributes: attributes(from: context, with: timestampMs), file: nil, line: nil)
    }

    func addTiming(name: NSString) {
        nativeRUM.addTiming(name: name as String)
    }

    // MARK: - Private methods

    private func attributes(from context: NSDictionary, with timestampMs: Int64) -> [String: Encodable] {
        var context = context as? [String: Any] ?? [:]
        context[Self.timestampKey] = timestampMs
        return castAttributesToSwift(context)
    }

    private func addResourceMetrics(key: NSString, resourceTimings: [String: Any]) {
        let fetch = timingValue(from: resourceTimings, for: Self.fetchTimingKey)
        let redirect = timingValue(from: resourceTimings, for: Self.redirectTimingKey)
        let dns = timingValue(from: resourceTimings, for: Self.dnsTimingKey)
        let connect = timingValue(from: resourceTimings, for: Self.connectTimingKey)
        let ssl = timingValue(from: resourceTimings, for: Self.sslTimingKey)
        let firstByte = timingValue(from: resourceTimings, for: Self.firstByteTimingKey)
        let download = timingValue(from: resourceTimings, for: Self.downloadTimingKey)

        if let fetch = fetch {
            nativeRUM.addResourceMetrics(
                resourceKey: key as String,
                fetch: fetch,
                redirection: redirect,
                dns: dns,
                connect: connect,
                ssl: ssl,
                firstByte: firstByte,
                download: download,
                responseSize: nil,
                attributes: [:]
            )
        }
    }

    private func timingValue(from timings: [String: Any], for timingName: String) -> (start: Date, end: Date)? {
        let timing = timings[timingName] as? [String: NSNumber]
        if let startInNs = timing?["startTime"]?.int64Value, let durationInNs = timing?["duration"]?.int64Value {
            return (
                Date(timeIntervalSince1970: TimeInterval(fromNs: startInNs)),
                Date(timeIntervalSince1970: TimeInterval(fromNs: startInNs + durationInNs))
            )
        }
        return nil
    }
}

internal extension TimeInterval {
    init(fromNs ns: Int64) { self = TimeInterval(Double(ns) / 1_000_000_000) }
}
