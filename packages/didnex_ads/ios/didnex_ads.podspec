Pod::Spec.new do |s|
  s.name = 'didnex_ads'
  s.version = '3.12.1'
  s.summary = 'Didnex advertising and optional native measurement bridge.'
  s.description = 'Flutter ad rendering with a host-supplied licensed measurement engine.'
  s.homepage = 'https://didnex.com/docs/publisher'
  s.license = { :type => 'MIT', :file => '../LICENSE' }
  s.author = { 'Didnex' => 'support@didnex.example' }
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*.swift'
  s.resource_bundles = { 'DidnexAdsPrivacy' => ['Resources/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.swift_version = '5.0'
end
