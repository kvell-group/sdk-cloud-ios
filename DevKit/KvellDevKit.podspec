Pod::Spec.new do |s|

  s.name         = 'KvellDevKit'
  s.version      = '0.1.0'
  s.summary      = 'Dev-only utilities for Kvell SDK (request signing, dev config).'
  s.description  = 'Development-only pod. NOT for distribution via Trunk. Provides JWT HS256 request signing and dev configuration for local demo builds.'

  s.homepage     = 'https://github.com/kvell/kvell-ios-sdk'
  s.license      = { :type => 'MIT' }
  s.author       = { 'Kvell' => 'sdk@kvell.io' }

  s.platform     = :ios
  s.ios.deployment_target = '15.0'

  # Локальный path — источник не нужен при :path => подключении
  s.source       = { :git => '', :tag => s.version.to_s }
  s.source_files = 'Sources/**/*.swift'

  s.dependency 'KvellNetworking'

  s.swift_version = '5.0'

end
