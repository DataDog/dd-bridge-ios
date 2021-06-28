/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import Datadog

internal class DdSdkImplementation: DdSdk {
    func initialize(configuration: DdSdkConfiguration) {
        let ddConfig = buildConfiguration(configuration: configuration)
        let consent = buildTrackingConsent(consent: configuration.trackingConsent)
        Datadog.initialize(appContext: Datadog.AppContext(), trackingConsent: consent, configuration: ddConfig)

        Global.rum = RUMMonitor.initialize()
    }

    func setAttributes(attributes: NSDictionary) {
        let castedAttributes = castAttributesToSwift(attributes)
        for (key, value) in castedAttributes {
            Global.rum.addAttribute(forKey: key, value: value)
        }
    }

    func setUser(user: NSDictionary) {
        var castedUser = castAttributesToSwift(user)
        let id = (castedUser.removeValue(forKey: "id") as? AnyEncodable)?.value as? String
        let name = (castedUser.removeValue(forKey: "name") as? AnyEncodable)?.value as? String
        let email = (castedUser.removeValue(forKey: "email") as? AnyEncodable)?.value as? String
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

        let additionalConfig: [String: Any] = configuration.additionalConfig as? [String: Any] ?? [:]
        _ = ddConfigBuilder.set(additionalConfiguration: additionalConfig)

        return ddConfigBuilder.build()
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
}
