/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import Datadog

internal class DdSdkImplementation: DdSdk {
    func initialize(configuration: DdSdkConfiguration) {
        let ddConfig: Datadog.Configuration
        if let rumAppID = configuration.applicationId as String? {
            ddConfig = Datadog.Configuration.builderUsing(
                rumApplicationID: rumAppID,
                clientToken: configuration.clientToken as String,
                environment: configuration.env as String
            )
            .set(rumSessionsSamplingRate: Float(configuration.sampleRate ?? 100.0))
            .build()
        } else {
            ddConfig = Datadog.Configuration.builderUsing(
                clientToken: configuration.clientToken as String,
                environment: configuration.env as String
            )
            .build()
        }
        Datadog.initialize(appContext: Datadog.AppContext(), trackingConsent: TrackingConsent.granted, configuration: ddConfig)
    }

    func setAttributes(attributes: NSDictionary) {
        let castedAttributes = castAttributesToSwift(attributes)
        for (key, value) in castedAttributes {
            Global.rum.addAttribute(forKey: key, value: value)
        }
    }

    func setUser(user: NSDictionary) {
        var castedUser = castAttributesToSwift(user)
        let id = castedUser.removeValue(forKey: "id")?.value as? String
        let name = castedUser.removeValue(forKey: "name")?.value as? String
        let email = castedUser.removeValue(forKey: "email")?.value as? String
        let extraInfo: [String: Encodable] = castedUser // everything what's left is an `extraInfo`

        Datadog.setUserInfo(id: id, name: name, email: email, extraInfo: extraInfo)
    }
}
