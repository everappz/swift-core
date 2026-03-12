Pod::Spec.new do |s|
  s.name             = 'InternxtSwiftCore'
  s.version          = '0.1.0'
  s.summary          = 'Internxt Swift Core library'
  s.description      = 'Core Swift library for Internxt services including crypto, networking, and drive APIs.'
  s.homepage         = 'https://github.com/everappz/swift-core'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Internxt' => 'hello@internxt.com' }
  s.source           = { :git => 'https://github.com/everappz/swift-core.git', :tag => s.version.to_s }

  s.macos.deployment_target = '10.15'
  s.swift_version    = '5.7'

  s.source_files     = 'Sources/InternxtSwiftCore/**/*.swift'

  s.dependency 'IDZSwiftCommonCrypto', '0.13.0'
end
