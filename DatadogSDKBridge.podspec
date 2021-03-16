Pod::Spec.new do |s|
  s.name             = 'DatadogSDKBridge'
  s.version          = '0.1.0'
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

  s.ios.deployment_target = '11.0'
  s.source_files = 'DatadogSDKBridge/Classes/**/*'
  s.dependency 'DatadogSDKObjc', '~> 1.5.1'

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'DatadogSDKBridge/Tests/*.swift'
  end
end
