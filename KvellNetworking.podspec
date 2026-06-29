Pod::Spec.new do |spec|

  spec.name         = 'KvellNetworking'
  spec.version      = '1.0.0'
  spec.summary      = "Networking layer for Kvell SDK"
  spec.description  = "Networking layer for Kvell SDK"

  spec.homepage     = 'https://github.com/kvell-group/sdk-cloud-ios'

  spec.license      = { :type => 'MIT' }

  spec.author       = { 'Kvell' => 'dev@kvell.io' }

  spec.platform     = :ios
  spec.ios.deployment_target = '15.0'

  spec.source       = { :git => 'https://github.com/kvell-group/sdk-cloud-ios.git', :tag => "#{spec.version}" }
  spec.source_files = 'networking/source/**/*.swift'

  spec.requires_arc = true

  spec.swift_version = '5.0'

end
