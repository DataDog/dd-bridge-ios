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

    func testSDKInitialization() {
        let originalConsolePrint = consolePrint
        defer { consolePrint = originalConsolePrint }

        var printedMessage = ""
        consolePrint = { msg in printedMessage += msg }

        DdSdkImplementation().initialize(configuration: validConfiguration)

        XCTAssertEqual(printedMessage, "")

        DdSdkImplementation().initialize(configuration: validConfiguration)

        XCTAssertEqual(printedMessage, "🔥 Datadog SDK usage error: SDK is already initialized.🔥 Datadog SDK usage error: The `RUMMonitor` instance was already created. Use existing `Global.rum` instead of initializing the `RUMMonitor` another time.")

        Datadog.flushAndDeinitialize()
    }

    func testBuildConfigurationNoUIKitByDefault() {
        let configuration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: nil)

        let ddConfig = DdSdkImplementation().buildConfiguration(configuration: configuration)

        XCTAssertNil(ddConfig.rumUIKitViewsPredicate)
    }

    func testBuildConfigurationUIKitTrackingDisabled() {
        let configuration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: ["_dd.native_view_tracking": false])

        let ddConfig = DdSdkImplementation().buildConfiguration(configuration: configuration)

        XCTAssertNil(ddConfig.rumUIKitViewsPredicate)
    }

    func testBuildConfigurationUIKitTrackingEnabled() {
        let configuration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: ["_dd.native_view_tracking": true])

        let ddConfig = DdSdkImplementation().buildConfiguration(configuration: configuration)

        XCTAssertNotNil(ddConfig.rumUIKitViewsPredicate)
    }

    func testSDKInitializationWithVerbosityDebug() {
        let validConfiguration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: ["_dd.sdk_verbosity": "debug"])

        DdSdkImplementation().initialize(configuration: validConfiguration)

        XCTAssertEqual(Datadog.verbosityLevel, LogLevel.debug)

        Datadog.flushAndDeinitialize()
    }

    func testSDKInitializationWithVerbosityInfo() {
        let validConfiguration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: ["_dd.sdk_verbosity": "info"])

        DdSdkImplementation().initialize(configuration: validConfiguration)

        XCTAssertEqual(Datadog.verbosityLevel, LogLevel.info)

        Datadog.flushAndDeinitialize()
    }

    func testSDKInitializationWithVerbosityWarn() {
        let validConfiguration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: ["_dd.sdk_verbosity": "warn"])

        DdSdkImplementation().initialize(configuration: validConfiguration)

        XCTAssertEqual(Datadog.verbosityLevel, LogLevel.warn)

        Datadog.flushAndDeinitialize()
    }

    func testSDKInitializationWithVerbosityError() {
        let validConfiguration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: ["_dd.sdk_verbosity": "error"])

        DdSdkImplementation().initialize(configuration: validConfiguration)

        XCTAssertEqual(Datadog.verbosityLevel, LogLevel.error)

        Datadog.flushAndDeinitialize()
    }

    func testSDKInitializationWithVerbosityNil() {
        let validConfiguration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: nil)

        DdSdkImplementation().initialize(configuration: validConfiguration)

        XCTAssertNil(Datadog.verbosityLevel)

        Datadog.flushAndDeinitialize()
    }

    func testSDKInitializationWithVerbosityUnknown() {
        let validConfiguration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: ["_dd.sdk_verbosity": "foo"])

        DdSdkImplementation().initialize(configuration: validConfiguration)

        XCTAssertNil(Datadog.verbosityLevel)

        Datadog.flushAndDeinitialize()
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

        // swiftlint:disable force_cast
        XCTAssertEqual(ddConfig.additionalConfiguration["foo"] as! String, "test")
        XCTAssertEqual(ddConfig.additionalConfiguration["bar"] as! Int, 42)
        // swiftlint:enable force_cast
    }

    func testBuildConfigurationWithNilServiceNameByDefault() {
        let configuration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: nil)

        let ddConfig = DdSdkImplementation().buildConfiguration(configuration: configuration)

        XCTAssertNil(ddConfig.serviceName)
    }

    func testBuildConfigurationWithServiceName() {
        let configuration = DdSdkConfiguration(clientToken: "client-token", env: "env", applicationId: "app-id", nativeCrashReportEnabled: true, sampleRate: 75.0, site: nil, trackingConsent: "pending", additionalConfig: ["_dd.service_name": "com.example.app"])

        let ddConfig = DdSdkImplementation().buildConfiguration(configuration: configuration)

        XCTAssertEqual(ddConfig.serviceName, "com.example.app")
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
        XCTAssertEqual(receivedUserInfo.extraInfo["extra-info-1"] as? Int64, 123)
        XCTAssertEqual(receivedUserInfo.extraInfo["extra-info-2"] as? String, "abc")
        XCTAssertEqual(receivedUserInfo.extraInfo["extra-info-3"] as? Bool, true)

        Datadog.flushAndDeinitialize()
    }

    func testSettingAttributes() {
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

        XCTAssertEqual(rumMonitorMock.receivedAttributes["attribute-1"] as? Int64, 123)
        XCTAssertEqual(rumMonitorMock.receivedAttributes["attribute-2"] as? String, "abc")
        XCTAssertEqual(rumMonitorMock.receivedAttributes["attribute-3"] as? Bool, true)

        XCTAssertEqual(GlobalState.globalAttributes["attribute-1"] as? Int64, 123)
        XCTAssertEqual(GlobalState.globalAttributes["attribute-2"] as? String, "abc")
        XCTAssertEqual(GlobalState.globalAttributes["attribute-3"] as? Bool, true)

        GlobalState.globalAttributes.removeAll()
        Datadog.flushAndDeinitialize()
    }

    func testBuildTrackingConsentPending() {
        let consent: NSString? = "pending"
        let trackingConsent = DdSdkImplementation().buildTrackingConsent(consent: consent)

        XCTAssertEqual(trackingConsent, TrackingConsent.pending)
    }

    func testBuildTrackingConsentGranted() {
        let consent: NSString? = "granted"
        let trackingConsent = DdSdkImplementation().buildTrackingConsent(consent: consent)

        XCTAssertEqual(trackingConsent, TrackingConsent.granted)
    }

    func testBuildTrackingConsentNotGranted() {
        let consent: NSString? = "not_granted"
        let trackingConsent = DdSdkImplementation().buildTrackingConsent(consent: consent)

        XCTAssertEqual(trackingConsent, TrackingConsent.notGranted)
    }

    func testBuildTrackingConsentNil() {
        let consent: NSString? = nil
        let trackingConsent = DdSdkImplementation().buildTrackingConsent(consent: consent)

        XCTAssertEqual(trackingConsent, TrackingConsent.pending)
    }

    func testBuildProxyConfiguration() {
        let configuration: NSMutableDictionary = [
            "_dd.proxy.address": "host",
            "_dd.proxy.port": 99,
            "_dd.proxy.username": "username",
            "_dd.proxy.password": "pwd"
        ]

        var proxy = DdSdkImplementation().buildProxyConfiguration(config: configuration)

        XCTAssertEqual(proxy?[kCFProxyUsernameKey] as? String, "username")
        XCTAssertEqual(proxy?[kCFProxyPasswordKey] as? String, "pwd")

        configuration.setValue("http", forKey: "_dd.proxy.type")
        proxy = DdSdkImplementation().buildProxyConfiguration(config: configuration)
        XCTAssertEqual(proxy?["HTTPEnable"] as? Int, 1)
        XCTAssertEqual(proxy?["HTTPProxy"] as? String, "host")
        XCTAssertEqual(proxy?["HTTPPort"] as? Int, 99)
        XCTAssertEqual(proxy?["HTTPSEnable"] as? Int, 1)
        XCTAssertEqual(proxy?["HTTPSProxy"] as? String, "host")
        XCTAssertEqual(proxy?["HTTPSPort"] as? Int, 99)

        configuration.setValue("https", forKey: "_dd.proxy.type")
        proxy = DdSdkImplementation().buildProxyConfiguration(config: configuration)
        XCTAssertEqual(proxy?["HTTPEnable"] as? Int, 1)
        XCTAssertEqual(proxy?["HTTPProxy"] as? String, "host")
        XCTAssertEqual(proxy?["HTTPPort"] as? Int, 99)
        XCTAssertEqual(proxy?["HTTPSEnable"] as? Int, 1)
        XCTAssertEqual(proxy?["HTTPSProxy"] as? String, "host")
        XCTAssertEqual(proxy?["HTTPSPort"] as? Int, 99)

        configuration.setValue("socks", forKey: "_dd.proxy.type")
        proxy = DdSdkImplementation().buildProxyConfiguration(config: configuration)
        XCTAssertEqual(proxy?["SOCKSEnable"] as? Int, 1)
        XCTAssertEqual(proxy?["SOCKSProxy"] as? String, "host")
        XCTAssertEqual(proxy?["SOCKSPort"] as? Int, 99)

        configuration.setValue("99", forKey: "_dd.proxy.port")
        proxy = DdSdkImplementation().buildProxyConfiguration(config: configuration)
        XCTAssertEqual(proxy?["SOCKSPort"] as? NSNumber, 99)
    }

    func testProxyConfiguration() {
        let configuration = DdSdkConfiguration(
            clientToken: "client-token",
            env: "env",
            applicationId: "app-id",
            nativeCrashReportEnabled: true,
            sampleRate: 75.0,
            site: nil,
            trackingConsent: "pending",
            additionalConfig: [
                "_dd.proxy.address": "host",
                "_dd.proxy.port": 99,
                "_dd.proxy.type": "http",
                "_dd.proxy.username": "username",
                "_dd.proxy.password": "pwd"
            ]
        )

        let ddConfig = DdSdkImplementation().buildConfiguration(configuration: configuration)

        XCTAssertEqual(ddConfig.proxyConfiguration?["HTTPProxy"] as? String, "host")
        XCTAssertEqual(ddConfig.proxyConfiguration?["HTTPPort"] as? NSNumber, 99)
        XCTAssertEqual(ddConfig.proxyConfiguration?[kCFProxyUsernameKey] as? String, "username")
        XCTAssertEqual(ddConfig.proxyConfiguration?[kCFProxyPasswordKey] as? String, "pwd")
    }
}

private class MockRUMMonitor: DDRUMMonitor {
    private(set) var receivedAttributes = [AttributeKey: AttributeValue]()

    override func addAttribute(forKey key: AttributeKey, value: AttributeValue) {
        receivedAttributes[key] = value
    }
}
