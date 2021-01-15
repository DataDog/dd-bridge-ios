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
            ddConfig = DDConfiguration.builder(
                rumApplicationID: rumAppID,
                clientToken: configuration.clientToken as String,
                environment: configuration.env as String
            )
            .build()
        } else {
            ddConfig = DDConfiguration.builder(
                clientToken: configuration.clientToken as String,
                environment: configuration.env as String
            )
            .build()
        }
        DDDatadog.initialize(appContext: DDAppContext(), configuration: ddConfig)
    }
}
