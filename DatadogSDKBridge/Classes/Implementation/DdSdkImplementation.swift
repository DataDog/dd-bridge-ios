/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import Datadog

internal class DdSdkImplementation: DdSdk {
    func initialize(configuration: DdSdkConfiguration) {
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
        case "us":
            _ = ddConfigBuilder.set(endpoint: .us)
        case "eu":
            _ = ddConfigBuilder.set(endpoint: .eu)
        case "gov":
            _ = ddConfigBuilder.set(endpoint: .gov)
        default:
            _ = ddConfigBuilder.set(endpoint: .us)
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

        if let proxyConfiguration = buildProxyConfiguration(config: additionalConfig) {
            _ = ddConfigBuilder.set(proxyConfiguration: proxyConfiguration)
        }

        return ddConfigBuilder.build()
    }

    func buildProxyConfiguration(config: NSDictionary?) -> [AnyHashable: Any]? {
        guard let address = config?["_dd.proxy.address"] as? String else {
            return nil
        }

        var proxy: [AnyHashable: Any] = [kCFNetworkProxiesHTTPEnable: true]
        proxy[kCFNetworkProxiesHTTPProxy] = address
        proxy[kCFNetworkProxiesHTTPPort] = config?["_dd.proxy.port"]
        proxy[kCFProxyUsernameKey] = config?["_dd.proxy.username"]
        proxy[kCFProxyPasswordKey] = config?["_dd.proxy.password"]

        if let port = config?["_dd.proxy.port"] as? Int {
            proxy[kCFNetworkProxiesHTTPPort] = port
        } else if let string = config?["_dd.proxy.port"] as? String, let port = Int(string) {
            proxy[kCFNetworkProxiesHTTPPort] = port
        }

        let type = config?["_dd.proxy.type"] as? String

        switch type {
        case "http":
            proxy[kCFProxyTypeKey] = kCFProxyTypeHTTP
        case "https":
            proxy[kCFProxyTypeKey] = kCFProxyTypeHTTPS
        case "socks":
            proxy[kCFProxyTypeKey] = kCFProxyTypeSOCKS
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
