/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import DatadogObjc

internal class DdSdkImplementation: DdSdk {
    func initialize(configuration: DdSdkConfiguration) {
        let ddConfig: DDConfiguration
        if let rumAppID = configuration.applicationId as String? {
            let builder = DDConfiguration.builder(
                rumApplicationID: rumAppID,
                clientToken: configuration.clientToken as String,
                environment: configuration.env as String
            )
            builder.set(rumSessionsSamplingRate: Float(configuration.sampleRate ?? 100.0))
            ddConfig = builder.build()
        } else {
            ddConfig = DDConfiguration.builder(
                clientToken: configuration.clientToken as String,
                environment: configuration.env as String
            )
            .build()
        }
        DDDatadog.initialize(appContext: DDAppContext(), trackingConsent: DDTrackingConsent.granted(), configuration: ddConfig)
    }
    
    func setAttributes(attributes: NSDictionary) {
        for key in attributes.allKeys {
            let strKey = String(describing: key)
            let value = attributes[key]
            DDGlobal.rum.addAttribute(forKey: strKey, value: value)
        }
    }
    
    func setUser(user: NSDictionary) {
        var id: String? = nil
        var name: String? = nil
        var email: String? = nil
        for key in user.allKeys {
            let strKey = String(describing: key)
            let value = user[key]
            if (strKey == "id") {
                id = String(describing:value)
            } else if (strKey == "name") {
                name = String(describing:value)
            } else if (strKey == "email") {
                email = String(describing:value)
            }
        }
        // TODO RUMM-1197 enable extraInfo in ObjC
        DDDatadog.setUserInfo(id: id, name: name, email: email)
    }
}
