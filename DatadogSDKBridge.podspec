Pod::Spec.new do |s|
  s.name             = 'DatadogSDKBridge'
  s.version          = '0.5.1'
  s.summary          = 'Datadog iOS SDK Bridge for cross-platform integrations.'

  s.homepage         = 'https://github.com/DataDog/dd-bridge-ios'
  s.license          = { :type => "Apache", :file => 'LICENSE' }
  s.authors          = {
      "Maciek Grzybowski" => "maciek.grzybowski@datadoghq.com",
      "Mert Buran" => "mert.buran@datadoghq.com"
  }
  s.source           = { :git => 'https://github.com/DataDog/dd-bridge-ios.git', :tag => s.version.to_s }

  s.homepage     = "https://www.datadoghq.com"
  s.social_media_url   = "https://twitter.com/datadoghq"

  s.swift_versions        = ['5.1']
  s.ios.deployment_target = '11.0'
  s.source_files = 'DatadogSDKBridge/Classes/**/*'
  s.dependency 'DatadogSDK', '~> 1.9.0'
end
