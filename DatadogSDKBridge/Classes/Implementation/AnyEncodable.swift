/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Datadog (https://www.datadoghq.com/).
* Copyright 2019-2020 Datadog, Inc.
*/

import Foundation

internal func castAttributesToSwift(_ attributes: NSDictionary) -> [String: Encodable] {
    return castAttributesToSwift(attributes as? [String: Any] ?? [:])
}

internal func castAttributesToSwift(_ attributes: [String: Any]) -> [String: Encodable] {
    var casted: [String: Encodable] = [:]

    attributes.forEach { key, value in
        if key.hasPrefix("_dd.") {
            casted[key] = castInternalAttribute(value: value)
        } else {
            casted[key] = castUserAttribute(value: value)
        }
    }

    return casted
}

/// Casts `Any` value to `Encodable?` by inspecting and unpacking its value.
/// This is necessary to handle values passed from Objective-C, which cannot be casted directly (they return `nil` for `as? Encodable`).
///
/// **Note**: It only supports selected primitive, non-sequence types.
private func castInternalAttribute(value: Any) -> Encodable? {
    switch value {
    case let string as String: // unpacking `NSTaggedPointerString`
        return string
    case let int64 as Int64: // unpacking `__NSCFNumber`
        return int64
    case let double as Double: // unpacking `__NSCFNumber` again; trying `Double` after `Int` as it's a wider type
        return double
    default:
        return nil
    }
}

/// Casts `Any` value to `Encodable` by wrapping it into `AnyEncodable` type erasure.
/// Ulike explicit casting implemented in `castUserAttribute`, this works for wider range of types, including sequences.
private func castUserAttribute(value: Any) -> Encodable? {
    return AnyEncodable(value)
}

/// Type erasing `Encodable` wrapper to bridge Objective-C's `Any` to Swift `Encodable`.
///
/// We cannot do it with `value as? Encodable` as values received from Objective-C are baked with special types, like
/// `NSTaggedPointerString`, `__NSCFNumber` or `Swift.__SwiftDeferredNSArray`. Those when casted with
/// just `as? Encodable` result with `nil`.
///
/// Inspired by `AnyCodable` by Flight-School (MIT):
/// https://github.com/Flight-School/AnyCodable/blob/master/Sources/AnyCodable/AnyEncodable.swift
internal class AnyEncodable: Encodable {
    internal let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let number as NSNumber:
            try encodeNSNumber(number, into: &container)
        case is NSNull, is Void:
            try container.encodeNil()
        case let string as String:
            try container.encode(string)
        case let date as Date:
            try container.encode(date)
        case let url as URL:
            try container.encode(url)
        case let array as [Any]:
            try container.encode(array.map { AnyEncodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyEncodable($0) })
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Value \(value) cannot be encoded - \(type(of: value)) is not supported by `AnyEncodable`."
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}

private func encodeNSNumber(_ nsnumber: NSNumber, into container: inout SingleValueEncodingContainer) throws {
    switch CFNumberGetType(nsnumber) {
    case .charType:
        try container.encode(nsnumber.boolValue)
    case .sInt8Type:
        try container.encode(nsnumber.int8Value)
    case .sInt16Type:
        try container.encode(nsnumber.int16Value)
    case .sInt32Type:
        try container.encode(nsnumber.int32Value)
    case .sInt64Type:
        try container.encode(nsnumber.int64Value)
    case .shortType:
        try container.encode(nsnumber.uint16Value)
    case .longType:
        try container.encode(nsnumber.uint32Value)
    case .longLongType:
        try container.encode(nsnumber.uint64Value)
    case .intType, .nsIntegerType, .cfIndexType:
        try container.encode(nsnumber.intValue)
    case .floatType, .float32Type:
        try container.encode(nsnumber.floatValue)
    case .doubleType, .float64Type, .cgFloatType:
        try container.encode(nsnumber.doubleValue)
    @unknown default:
        return
    }
}
