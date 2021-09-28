# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

target 'PhoniexAntMediaFramework' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  
  pod 'Starscream', '~> 3.1.0'
  pod 'CocoaAsyncSocket', '~> 7.6.5'
  
  pod 'RxCocoa', '~> 5.1.1'
  pod 'RxOptional', '~> 4.1.0'
  pod 'RxSwiftExt', '~> 5.2.0'
  
  pod 'SwiftPhoenixClient', '~> 1.3.0'
  pod 'GoogleWebRTC', '~> 1.1.31999'
    
  pod 'RxReachability', '~> 1.0.0'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
