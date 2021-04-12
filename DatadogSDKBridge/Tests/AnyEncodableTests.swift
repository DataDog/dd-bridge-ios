/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSDKBridge

class AnyEncodableTests: XCTestCase {
    func testWhenWrappingAnyTypeUsingAnyEncodable_thenItGetsEncodedInExpectedFormat() throws {
        // Given
        let dictionary: [String: Any] = [
            "array": [1, 2, 3],
            "boolean": true,
            "date": Date(timeIntervalSince1970: 0),
            "double": 3.141592653589793,
            "integer": 42,
            "nested": [
                "a": "alpha",
                "b": "bravo",
                "c": "charlie"
            ],
            "null": NSNull(),
            "string": "string",
            "url": NSURL(string: "https://datadoghq.com")!
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
