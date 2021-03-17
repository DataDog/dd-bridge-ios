/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSDKBridge
@testable import Datadog

internal class DdSdkTests: XCTestCase {
    private let validConfiguration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, additionalConfig: nil)

    func testSDKInitialization() {
        let originalConsolePrint = consolePrint
        defer { consolePrint = originalConsolePrint }

        var printedMessage = ""
        consolePrint = { msg in printedMessage += msg }

        DdSdkImplementation().initialize(configuration: validConfiguration)

        XCTAssertEqual(printedMessage, "")

        DdSdkImplementation().initialize(configuration: validConfiguration)

        XCTAssertEqual(printedMessage, "🔥 Datadog SDK usage error: SDK is already initialized.")
    }
}
