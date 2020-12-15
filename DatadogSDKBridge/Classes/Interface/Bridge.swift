/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

public enum Bridge {
  public static func getDdLogs() -> DdLogs {
     return DdLogsImplementation()
  }

  public static func getDdRum() -> DdRum {
     return DdRumImplementation()
  }

  public static func getDdTrace() -> DdTrace {
     return DdTraceImpementation()
  }

  public static func getDdSdk() -> DdSdk {
     return DdSdkImplementation()
  }
}
