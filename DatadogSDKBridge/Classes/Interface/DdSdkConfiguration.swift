/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2016-Present Datadog, Inc.
 */

import Foundation

/**
 A configuration object to initialize Datadog's features.
 - Parameters:
     - clientToken: A valid Datadog client token.
     - env: The application’s environment, for example: prod, pre-prod, staging, etc.
     - applicationId: The RUM application ID.
     - nativeCrashReportEnabled: Whether the SDK should track native (pure iOS or pure Android) crashes (default is false).
     - sampleRate: The sample rate (between 0 and 100) of RUM sessions kept.
     - additionalConfig: Additional configuration parameters.
 */
@objc(DdSdkConfiguration)
public class DdSdkConfiguration: NSObject {
    public var clientToken: NSString = ""
    public var env: NSString = ""
    public var applicationId: NSString? = nil
    public var nativeCrashReportEnabled: Bool? = nil
    public var sampleRate: Double? = nil
    public var additionalConfig: NSDictionary? = nil

    public init(
        clientToken: NSString,
        env: NSString,
        applicationId: NSString?,
        nativeCrashReportEnabled: Bool?,
        sampleRate: Double?,
        additionalConfig: NSDictionary?
    ) {
        self.clientToken = clientToken
        self.env = env
        self.applicationId = applicationId
        self.nativeCrashReportEnabled = nativeCrashReportEnabled
        self.sampleRate = sampleRate
        self.additionalConfig = additionalConfig
    }
}
