# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

use_frameworks!

############################ Pods ############################

def app_pods
  pod 'ENSwiftSideMenu', '~> 0.1.4'
  pod 'Texture'
  pod 'SwiftyRSA'
  pod 'SwiftLint' # todo - add linting rules
  pod 'SwiftFormat/CLI'
end

def ui_pods
  pod 'Texture'
end

############################ Targets ############################
target 'FlowCrypt' do
  app_pods
end 

target 'FlowCryptUI' do
  ui_pods
end

target 'FlowCryptUIApplication' do
  ui_pods
end

## Set IPHONEOS_DEPLOYMENT_TARGET for all pods
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
