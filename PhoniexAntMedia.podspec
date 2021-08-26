Pod::Spec.new do |spec|

  spec.name         = "PhoniexAntMedia"
  spec.version      = "0.1.0"
  spec.summary      = "It's merging two pods into single"
  spec.description  = "This is about to merge two framework AntMedia and Phoniex into single one"
  spec.homepage     = "https://github.com/JayeshMardiya/PhoniexAntMedia"
  spec.license      = "MIT"
  spec.author       = { "Jayesh Mardiya" => "mardiyajayesh@gmail.com" }
  spec.platform     = :ios, "12.1"
  spec.source       = { :git => "https://github.com/JayeshMardiya/PhoniexAntMedia.git", :branch => "master" }
  spec.source_files = "PhoniexAntMediaFramework/Sources/**/*.{h,m,swift}"
  spec.resources    = "PhoniexAntMediaFramework/Resources/**/*.*"
  spec.swift_versions = "5.0"

  spec.ios.deployment_target = '12.1'
  
  spec.xcconfig = { 'CLANG_MODULES_AUTOLINK' => 'YES', 'OTHER_LDFLAGS' => '-ObjC', 'ENABLE_BITCODE' => 'NO' }
  spec.requires_arc = true
  spec.static_framework = true
  
  spec.frameworks   = ['UIKit', 'OpenGLES', 'CoreMedia', 'CoreVideo', 'QuartzCore', 'AVFoundation']
  spec.libraries = 'icucore', 'stdc++'

  spec.dependency 'Starscream', '~> 3.1.0'
  spec.dependency 'CocoaAsyncSocket', '~> 7.6.5'
  
  spec.dependency 'RxCocoa', '~> 5.1.3'
  spec.dependency 'RxOptional'
  spec.dependency 'RxSwiftExt'
  
  spec.dependency "GoogleWebRTC", '1.1.31999'
  
  spec.dependency 'Swinject', '2.7.1'
  
  spec.dependency 'RxReachability'
  
  spec.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  spec.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
end
