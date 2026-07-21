#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint telebirr_inapp_purchase_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'telebirr_inapp_purchase_plus'
  s.version          = '1.0.5'
  s.summary          = 'Flutter bridge for the Telebirr InApp Purchase SDK.'
  s.description      = <<-DESC
Production-ready Flutter bridge for the Telebirr InApp Purchase SDK. Backend
order creation and signing are intentionally excluded.
                       DESC
  s.homepage         = 'https://github.com/Dream-Technologies-PLC/telebirr_inapp_purchase_plus'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Dream Technologies PLC' => 'https://dreamtech.et' }
  s.source           = { :git => 'https://github.com/Dream-Technologies-PLC/telebirr_inapp_purchase_plus.git', :tag => "v#{s.version}" }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  if File.exist?(File.join(__dir__, 'Frameworks/EthiopiaPaySDK.xcframework'))
    s.vendored_frameworks = 'Frameworks/EthiopiaPaySDK.xcframework'
  elsif File.exist?(File.join(__dir__, 'Frameworks/EthiopiaPaySDK.framework'))
    s.vendored_frameworks = 'Frameworks/EthiopiaPaySDK.framework'
  end

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  s.user_target_xcconfig = {
    'ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'telebirr_inapp_purchase_plus_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
