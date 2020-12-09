/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import class Datadog.HTTPHeadersWriter

@objcMembers
public class DDHTTPHeadersWriter: NSObject {
    let swiftHTTPHeadersWriter = HTTPHeadersWriter()

    override public init() {}
}
