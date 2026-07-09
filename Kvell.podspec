Pod::Spec.new do |spec|

  spec.name         = 'Kvell'
  spec.version      = '1.1.0'
  spec.summary      = 'Core library that allows you to use internet acquiring from Kvell in your app'
  spec.description  = 'Core library that allows you to use internet acquiring from Kvell in your app.'

  spec.homepage     = 'https://github.com/kvell-group/sdk-cloud-ios'

  spec.license      = { :type => 'MIT' }

  spec.author       = { 'Kvell' => 'dev@kvell.io' }

  spec.platform     = :ios
  spec.ios.deployment_target = '15.0'

  spec.source       = { :git => 'https://github.com/kvell-group/sdk-cloud-ios.git', :tag => "#{spec.version}" }
  spec.source_files = 'sdk/Sources/**/*.swift'

  spec.resource_bundles = { 'KvellSDK' => ['sdk/Resources/**/*.{txt,json,png,jpeg,jpg,storyboard,xib,xcassets,ttf,otf}'] }

  spec.requires_arc = true

  spec.dependency 'KvellNetworking'

  spec.swift_version = '5.0'

end
