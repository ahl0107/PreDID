#
#  Be sure to run `pod spec lint hive.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name = 'PreDID'
  s.version = '3.0.0'
  s.summary ='this is a test.'
  s.swift_version  = '4.2'
  s.description = 'this is a test. 00000'
  s.homepage     = 'https://github.com/ahl0107'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'did-dev' => 'liaihong@gmail.com' }
  s.platform     = :ios, '11.0'
  s.ios.deployment_target = '11.0'
  s.source       = {:git => 'https://github.com/ahl0107/PreDID.git', :tag => s.version}
  s.source_files = 'ElastosDIDSDK/**/*.{h,m,swift}','Externals/Antlr4/**/**/*.{h,m,swift,interp,tokens,g4}','Externals/base58/*.{swift}','Externals/ByteBuffer/*.{swift}','Externals/CryptorECC/*.{swift}','Externals/HDKey/include/*.{h,swift}','Externals/SwiftJWT/*.{swift}'
  s.vendored_libraries = 'Externals/HDKey/lib/*.a'
  s.dependency 'PromiseKit','~> 6.9'
  s.dependency 'BlueRSA', '~> 1.0'
  s.dependency 'LoggerAPI','~> 1.7'
  s.dependency 'KituraContracts','~> 1.1'
  s.dependency 'BlueCryptor', '~> 1.0'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end

