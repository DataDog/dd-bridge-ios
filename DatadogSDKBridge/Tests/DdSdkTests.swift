/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSDKBridge
@testable import Datadog

internal class DdSdkTests: XCTestCase {
    private let validConfiguration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: nil)

    func testSDKInitialization() throws {
        let originalConsolePrint = consolePrint
        defer { consolePrint = originalConsolePrint }

        var printedMessage = ""
        consolePrint = { msg in printedMessage += msg }

        DdSdkImplementation().initialize(configuration: validConfiguration)

        XCTAssertEqual(printedMessage, "")

        DdSdkImplementation().initialize(configuration: validConfiguration)

        XCTAssertEqual(printedMessage, "🔥 Datadog SDK usage error: SDK is already initialized.")

        try Datadog.deinitializeOrThrow()
    }
    
    func testBuildConfigurationDefaultEndpoint() {
        let configuration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: nil)
        
        let ddConfig = DdSdkImplementation().buildConfiguration(configuration: configuration)
        
        XCTAssertEqual(ddConfig.datadogEndpoint, Datadog.Configuration.DatadogEndpoint.us)
    }
    
    func testBuildConfigurationUSEndpoint() {
        let configuration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: "US", trackingConsent: "pending", additionalConfig: nil)
        
        let ddConfig = DdSdkImplementation().buildConfiguration(configuration: configuration)
        
        XCTAssertEqual(ddConfig.datadogEndpoint, Datadog.Configuration.DatadogEndpoint.us)
    }
    
    func testBuildConfigurationEUEndpoint() {
        let configuration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: "EU", trackingConsent: "pending", additionalConfig: nil)
        
        let ddConfig = DdSdkImplementation().buildConfiguration(configuration: configuration)
        
        XCTAssertEqual(ddConfig.datadogEndpoint, Datadog.Configuration.DatadogEndpoint.eu)
    }
    
    func testBuildConfigurationGOVEndpoint() {
        let configuration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: "GOV", trackingConsent: "pending", additionalConfig: nil)
        
        let ddConfig = DdSdkImplementation().buildConfiguration(configuration: configuration)
        
        XCTAssertEqual(ddConfig.datadogEndpoint, Datadog.Configuration.DatadogEndpoint.gov)
    }
    
    func testBuildConfigurationAdditionalConfig() {
        let configuration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: ["foo": "test", "bar": 42])
        
        let ddConfig = DdSdkImplementation().buildConfiguration(configuration: configuration)
        
        XCTAssertEqual(ddConfig.additionalConfiguration["foo"] as! String, "test")
        XCTAssertEqual(ddConfig.additionalConfiguration["bar"] as! Int, 42)
    }

    func testSettingUserInfo() throws {
        let bridge = DdSdkImplementation()
        bridge.initialize(configuration: validConfiguration)

        bridge.setUser(
            user: NSDictionary(
                dictionary: [
                    "id": "abc-123",
                    "name": "John Doe",
                    "email": "john@doe.com",
                    "extra-info-1": 123,
                    "extra-info-2": "abc",
                    "extra-info-3": true
                ]
            )
        )

        let receivedUserInfo = try XCTUnwrap(Datadog.instance?.userInfoProvider.value)
        XCTAssertEqual(receivedUserInfo.id, "abc-123")
        XCTAssertEqual(receivedUserInfo.name, "John Doe")
        XCTAssertEqual(receivedUserInfo.email, "john@doe.com")
        XCTAssertEqual((receivedUserInfo.extraInfo["extra-info-1"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual((receivedUserInfo.extraInfo["extra-info-2"] as? AnyEncodable)?.value as? String, "abc")
        XCTAssertEqual((receivedUserInfo.extraInfo["extra-info-3"] as? AnyEncodable)?.value as? Bool, true)

        try Datadog.deinitializeOrThrow()
    }

    func testSettingAttributes() throws {
        let bridge = DdSdkImplementation()
        bridge.initialize(configuration: validConfiguration)

        let rumMonitorMock = MockRUMMonitor()
        Global.rum = rumMonitorMock

        bridge.setAttributes(
            attributes: NSDictionary(
                dictionary: [
                    "attribute-1": 123,
                    "attribute-2": "abc",
                    "attribute-3": true
                ]
            )
        )

        XCTAssertEqual((rumMonitorMock.receivedAttributes["attribute-1"] as? AnyEncodable)?.value as? Int, 123)
        XCTAssertEqual((rumMonitorMock.receivedAttributes["attribute-2"] as? AnyEncodable)?.value as? String, "abc")
        XCTAssertEqual((rumMonitorMock.receivedAttributes["attribute-3"] as? AnyEncodable)?.value as? Bool, true)

        try Datadog.deinitializeOrThrow()
    }
    
    func testBuildTrackingConsentPending() {
        
        let consent:NSString? = "pending"
        
        let trackingConsent = DdSdkImplementation().buildTrackingConsent(consent: consent)
        
        XCTAssertEqual(trackingConsent, TrackingConsent.pending)
    }
    
    func testBuildTrackingConsentGranted() {
        
        let consent:NSString? = "granted"
        
        let trackingConsent = DdSdkImplementation().buildTrackingConsent(consent: consent)
        
        XCTAssertEqual(trackingConsent, TrackingConsent.granted)
    }
    
    func testBuildTrackingConsentNotGranted() {
        
        let consent:NSString? = "not_granted"
        
        let trackingConsent = DdSdkImplementation().buildTrackingConsent(consent: consent)
        
        XCTAssertEqual(trackingConsent, TrackingConsent.notGranted)
    }
    
    func testBuildTrackingConsentNil() {
        
        let consent: NSString? = nil
        
        let trackingConsent = DdSdkImplementation().buildTrackingConsent(consent: consent)
        
        XCTAssertEqual(trackingConsent, TrackingConsent.pending)
    }
}

private class MockRUMMonitor: DDRUMMonitor {
    private(set) var receivedAttributes = [AttributeKey: AttributeValue]()

    override func addAttribute(forKey key: AttributeKey, value: AttributeValue) {
        receivedAttributes[key] = value
    }
}
