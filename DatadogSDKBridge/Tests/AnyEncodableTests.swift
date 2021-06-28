/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSDKBridge

internal class AnyEncodableTests: XCTestCase {
    // MARK: - Casting attributes

    func testWhenCastingUserAttributes_thenItWrapsThemInAnyEncodableContainer() throws {
        // Given
        let userAttributes = NSDictionary(
            dictionary: [
                "array": [1, 2, 3],
                "boolean": true,
                "date": Date(timeIntervalSince1970: 123),
                "double": 3.141_592_653_589_793,
                "integer": 42,
                "nested": [
                    "a": "alpha",
                    "b": "bravo",
                    "c": "charlie"
                ],
                "null": NSNull(),
                "string": "string",
                "url": NSURL(string: "https://datadoghq.com")!, // swiftlint:disable:this force_unwrapping
            ]
        )

        // When
        let castedAttributes = castAttributesToSwift(userAttributes)

        // Then
        XCTAssertEqual(castedAttributes.count, userAttributes.count)
        XCTAssertEqual((castedAttributes["array"] as? AnyEncodable)?.value as? [Int], [1, 2, 3])
        XCTAssertEqual((castedAttributes["boolean"] as? AnyEncodable)?.value as? Bool, true)
        XCTAssertEqual((castedAttributes["date"] as? AnyEncodable)?.value as? Date, Date(timeIntervalSince1970: 123))
        XCTAssertEqual((castedAttributes["double"] as? AnyEncodable)?.value as? Double, 3.141_592_653_589_793)
        XCTAssertEqual((castedAttributes["integer"] as? AnyEncodable)?.value as? Int, 42)
        XCTAssertEqual((castedAttributes["nested"] as? AnyEncodable)?.value as? [String: String], ["a": "alpha", "b": "bravo", "c": "charlie"])
        XCTAssertEqual((castedAttributes["null"] as? AnyEncodable)?.value as? NSNull, NSNull())
        XCTAssertEqual((castedAttributes["string"] as? AnyEncodable)?.value as? String, "string")
        XCTAssertEqual((castedAttributes["url"] as? AnyEncodable)?.value as? URL, URL(string: "https://datadoghq.com"))
    }

    func testWhenCastingInternalAttributes_thenItDoesNotEreaseItsType() throws {
        // Given
        let userAttributes = NSDictionary(
            dictionary: [
                "_dd.string": "string",
                "_dd.boolean": true,
                "_dd.double": 3.141_592_653_589_793,
                "_dd.integer": 42,
            ]
        )

        // When
        let castedAttributes = castAttributesToSwift(userAttributes)

        // Then
        XCTAssertEqual(castedAttributes.count, userAttributes.count)
        XCTAssertEqual(castedAttributes["_dd.string"] as? String, "string")
        XCTAssertEqual(castedAttributes["_dd.boolean"] as? Int64, 1, "Boolean value must be casted to `Int64`")
        XCTAssertEqual(castedAttributes["_dd.double"] as? Double, 3.141_592_653_589_793)
        XCTAssertEqual(castedAttributes["_dd.integer"] as? Int64, 42)
    }

    // MARK: - Encoding

    func testWhenWrappingUserAttributesInAnyEncodable_thenTheyGetEncodedInExpectedFormat() throws {
        // Given
        let dictionary: [String: Any] = [
            "array": [1, 2, 3],
            "boolean": true,
            "date": Date(timeIntervalSince1970: 0),
            "double": 3.141_592_653_589_793,
            "integer": 42,
            "nested": [
                "a": "alpha",
                "b": "bravo",
                "c": "charlie"
            ],
            "null": NSNull(),
            "string": "string",
            "url": NSURL(string: "https://datadoghq.com") as Any
        ]

        // When
        let anyEncodableDictionary = dictionary.mapValues { anyValue in AnyEncodable(anyValue) }
        let receivedJSONString = try encodeToJSONString(anyEncodableDictionary)

        // Then
        let expectedJSONString = """
        {
          "array" : [
            1,
            2,
            3
          ],
          "boolean" : true,
          "date" : "1970-01-01T00:00:00Z",
          "double" : 3.1415926535897931,
          "integer" : 42,
          "nested" : {
            "a" : "alpha",
            "b" : "bravo",
            "c" : "charlie"
          },
          "null" : null,
          "string" : "string",
          "url" : "https:\\/\\/datadoghq.com"
        }
        """

        XCTAssertEqual(receivedJSONString, expectedJSONString)
    }

    private func encodeToJSONString(_ dictionary: [String: AnyEncodable]) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let jsonData = try encoder.encode(dictionary)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
}
