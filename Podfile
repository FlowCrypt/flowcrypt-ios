# Uncomment the next line to define a global platform for your project
platform :ios, '12.2'

use_frameworks!

############################ Pods ############################

def app_pods
  pod 'GoogleSignIn'
  pod 'mailcore2-ios'
  pod 'MBProgressHUD'
  pod 'SwiftLint' # todo - add linting rules
  pod 'Toast', '~> 4.0.0'
  pod 'ENSwiftSideMenu', '~> 0.1.4'
  pod 'Texture'
  pod 'SwiftLint'
  pod 'SwiftFormat/CLI'
end

def shared_pods
  pod 'RealmSwift'
  pod 'PromisesSwift'
  pod 'SwiftyRSA'
  pod 'IDZSwiftCommonCrypto'
  pod 'mailcore2-ios'
  pod 'BigInt', '~> 5.0'
end

def ui_pods
  pod 'Texture'
end

def google_pods
  pod 'GoogleAPIClientForREST/Gmail'
end

############################ Targets ############################
target 'FlowCrypt' do
  shared_pods
  app_pods
  google_pods
end

target 'FlowCryptTests' do
  shared_pods
  inherit! :search_paths
end

target 'FlowCryptUI' do
  ui_pods
end

target 'FlowCryptUIApplication' do
  ui_pods
end

target 'FlowCryptUITests' do
  pod 'GoogleSignIn'
end
