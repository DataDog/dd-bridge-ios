/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import Datadog
import DatadogCrashReporting

internal class DdSdkImplementation: DdSdk {
    func initialize(configuration: DdSdkConfiguration) {
        if Datadog.isInitialized {
            // Initializing the SDK twice results in Global.rum and
            // Global.sharedTracer to be set to no-op instances
            consolePrint("Datadog SDK is already initialized, skipping initialization.")
            return
        }
        setVerbosityLevel(additionalConfig: configuration.additionalConfig)

        let ddConfig = buildConfiguration(configuration: configuration)
        let consent = buildTrackingConsent(consent: configuration.trackingConsent)
        Datadog.initialize(appContext: Datadog.AppContext(), trackingConsent: consent, configuration: ddConfig)

        Global.rum = RUMMonitor.initialize()
    }

    func setAttributes(attributes: NSDictionary) {
        let castedAttributes = castAttributesToSwift(attributes)
        for (key, value) in castedAttributes {
            Global.rum.addAttribute(forKey: key, value: value)
            GlobalState.addAttribute(forKey: key, value: value)
        }
    }

    func setUser(user: NSDictionary) {
        var castedUser = castAttributesToSwift(user)
        let id = castedUser.removeValue(forKey: "id") as? String
        let name = castedUser.removeValue(forKey: "name") as? String
        let email = castedUser.removeValue(forKey: "email") as? String
        let extraInfo: [String: Encodable] = castedUser // everything what's left is an `extraInfo`

        Datadog.setUserInfo(id: id, name: name, email: email, extraInfo: extraInfo)
    }

    func setTrackingConsent(trackingConsent: NSString) {
        Datadog.set(trackingConsent: buildTrackingConsent(consent: trackingConsent))
    }

    func buildConfiguration(configuration: DdSdkConfiguration) -> Datadog.Configuration {
        let ddConfigBuilder: Datadog.Configuration.Builder
        if let rumAppID = configuration.applicationId as String? {
            ddConfigBuilder = Datadog.Configuration.builderUsing(
                rumApplicationID: rumAppID,
                clientToken: configuration.clientToken as String,
                environment: configuration.env as String
            )
            .set(rumSessionsSamplingRate: Float(configuration.sampleRate ?? 100.0))
        } else {
            ddConfigBuilder = Datadog.Configuration.builderUsing(
                clientToken: configuration.clientToken as String,
                environment: configuration.env as String
            )
        }

        switch configuration.site?.lowercased ?? "us" {
        case "us1", "us":
            _ = ddConfigBuilder.set(endpoint: .us1)
        case "eu1", "eu":
            _ = ddConfigBuilder.set(endpoint: .eu1)
        case "us3":
            _ = ddConfigBuilder.set(endpoint: .us3)
        case "us5":
            _ = ddConfigBuilder.set(endpoint: .us5)
        case "us1_fed", "gov":
            _ = ddConfigBuilder.set(endpoint: .us1_fed)
        default:
            _ = ddConfigBuilder.set(endpoint: .us1)
        }

        let additionalConfig = configuration.additionalConfig

        if let additionalConfiguration = additionalConfig as? [String: Any] {
            _ = ddConfigBuilder.set(additionalConfiguration: additionalConfiguration)
        }

        if let enableViewTracking = additionalConfig?["_dd.native_view_tracking"] as? Bool, enableViewTracking {
            _ = ddConfigBuilder.trackUIKitRUMViews()
        }

        if let serviceName = additionalConfig?["_dd.service_name"] as? String {
            _ = ddConfigBuilder.set(serviceName: serviceName)
        }

        if let threshold = additionalConfig?["_dd.long_task.threshold"] as? TimeInterval {
            // `_dd.long_task.threshold` attribute is in milliseconds
            _ = ddConfigBuilder.trackRUMLongTasks(threshold: threshold / 1_000)
        }

        if let firstPartyHosts = additionalConfig?["_dd.first_party_hosts"] as? [String] {
            _ = ddConfigBuilder.trackURLSession(firstPartyHosts: Set(firstPartyHosts))
        }

        if let proxyConfiguration = buildProxyConfiguration(config: additionalConfig) {
            _ = ddConfigBuilder.set(proxyConfiguration: proxyConfiguration)
        }

        if configuration.nativeCrashReportEnabled ?? false {
            _ = ddConfigBuilder.enableCrashReporting(using: DDCrashReportingPlugin())
        }

        return ddConfigBuilder.build()
    }

    func buildProxyConfiguration(config: NSDictionary?) -> [AnyHashable: Any]? {
        guard let address = config?["_dd.proxy.address"] as? String else {
            return nil
        }

        var proxy: [AnyHashable: Any] = [:]
        proxy[kCFProxyUsernameKey] = config?["_dd.proxy.username"]
        proxy[kCFProxyPasswordKey] = config?["_dd.proxy.password"]

        let type = config?["_dd.proxy.type"] as? String
        var port = config?["_dd.proxy.port"] as? Int
        if let string = config?["_dd.proxy.port"] as? String {
            port = Int(string)
        }

        switch type {
        case "http", "https":
            // CFNetwork support HTTP and tunneling HTTPS proxies.
            // As intakes will most likely be https, we enable both channels.
            //
            // We use constants string keys because there is an issue with
            // cross-platform availability for proxy configuration symbols.
            // see. https://developer.apple.com/forums/thread/19356?answerId=131709022#131709022
            proxy["HTTPEnable"] = 1
            proxy["HTTPProxy"] = address
            proxy["HTTPPort"] = port
            proxy["HTTPSEnable"] = 1
            proxy["HTTPSProxy"] = address
            proxy["HTTPSPort"] = port
        case "socks":
            proxy["SOCKSEnable"] = 1
            proxy["SOCKSProxy"] = address
            proxy["SOCKSPort"] = port
        default:
            break
        }

        return proxy
    }

    func buildTrackingConsent(consent: NSString?) -> TrackingConsent {
        let trackingConsent: TrackingConsent
        switch consent?.lowercased {
        case "pending":
            trackingConsent = .pending
        case "granted":
            trackingConsent = .granted
        case "not_granted":
            trackingConsent = .notGranted
        default:
            trackingConsent = .pending
        }
        return trackingConsent
    }

    func setVerbosityLevel(additionalConfig: NSDictionary?) {
        let verbosityLevel = (additionalConfig?["_dd.sdk_verbosity"]) as? NSString
        switch verbosityLevel?.lowercased {
        case "debug":
            Datadog.verbosityLevel = .debug
        case "info":
            Datadog.verbosityLevel = .info
        case "warn":
            Datadog.verbosityLevel = .warn
        case "error":
            Datadog.verbosityLevel = .error
        default:
            Datadog.verbosityLevel = nil
        }
    }
}
