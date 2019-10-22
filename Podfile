# Uncomment the next line to define a global platform for your project
platform :ios, '12.2'


target 'FlowCrypt' do
  use_frameworks!
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
  pod 'RxSwift', '~> 5'
  pod 'RxCocoa', '~> 5'
  pod 'Texture'
end

target 'FlowCryptTests' do
  use_frameworks!
  pod 'PromisesSwift'
  pod 'SwiftyRSA'
  pod 'RealmSwift'
  pod 'IDZSwiftCommonCrypto'
  pod 'mailcore2-ios'
  pod 'RxBlocking', '~> 5'
  pod 'RxTest', '~> 5'
  inherit! :search_paths
end

target 'FlowCryptUITests' do
  use_frameworks!
  pod 'GoogleSignIn'

end
