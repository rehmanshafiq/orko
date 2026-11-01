Pod::Spec.new do |s|
  s.name             = 'app_integrity'
  s.version          = '1.0.0'
  s.summary          = 'Apple App Attest bridge for the Hubco app.'
  s.description      = 'In-repo plugin exposing DCAppAttestService to Dart.'
  s.homepage         = 'https://orkofleet.com'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'Orko' => 'dev@orkofleet.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '14.0'
  s.frameworks       = 'DeviceCheck', 'CryptoKit', 'Security'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
