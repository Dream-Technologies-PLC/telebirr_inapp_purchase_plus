#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint telebirr_inapp_purchase_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'telebirr_inapp_purchase_plus'
  s.version          = '0.0.3'
  s.summary          = 'Flutter bridge for the Telebirr InApp Purchase SDK.'
  s.description      = <<-DESC
Production-ready Flutter bridge for the Telebirr InApp Purchase SDK. Backend
order creation and signing are intentionally excluded.
                       DESC
  s.homepage         = 'https://github.com/Dream-Technologies-PLC/telebirr_inapp_purchase_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Telebirr InApp Purchase Plus Maintainers' => 'opensource@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.vendored_frameworks = 'Frameworks/EthiopiaPaySDK.framework' if File.exist?(File.join(__dir__, 'Frameworks/EthiopiaPaySDK.framework'))

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'telebirr_inapp_purchase_plus_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
