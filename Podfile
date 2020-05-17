# Uncomment the next line to define a global platform for your project
platform :ios, '12.2'

use_frameworks!

target 'FlowCrypt' do
  pod 'GoogleSignIn'
  pod 'mailcore2-ios'
  pod 'MBProgressHUD'
  pod 'RealmSwift'
  pod 'SwiftLint' # todo - add linting rules
  pod 'PromisesSwift'
  pod 'SwiftyRSA'
  pod 'IDZSwiftCommonCrypto'
  pod 'Toast', '~> 4.0.0'
  pod 'ENSwiftSideMenu', '~> 0.1.4'
  pod 'Texture'
  pod 'SwiftLint'
  pod 'SwiftFormat/CLI'
end

target 'FlowCryptTests' do
  pod 'PromisesSwift'
  pod 'SwiftyRSA'
  pod 'RealmSwift'
  pod 'IDZSwiftCommonCrypto'
  pod 'mailcore2-ios'
  inherit! :search_paths
end

def ui_pods 
  pod 'Texture'
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
