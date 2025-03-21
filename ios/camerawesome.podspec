#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint camerawesome.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'camerawesome'
  s.version          = '0.0.1'
  s.summary          = 'An open source camera plugin by the community for the community'
  s.description      = <<-DESC
An open source camera plugin by the community for the community
                       DESC
  s.homepage         = 'http://apparencekit.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Apparence.io' => 'hello@apparence.io' }
  s.source           = { :path => '.' }
  s.source_files = 'camerawesome/Sources/camerawesome/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'
  s.ios.deployment_target = '12.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  #   s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
