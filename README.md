# flowcrypt-ios

![Build Status](https://flowcrypt.semaphoreci.com/badges/flowcrypt-ios.svg?key=9bd38bf4-4a38-4cb3-b551-38302af1eb07)

FlowCrypt iOS App, download from https://flowcrypt.com/download

### Installation

You will need to have Xcode *(version 12.4)* installed
* clone the repo
```sh
git clone https://github.com/FlowCrypt/flowcrypt-ios.git
cd flowcrypt-ios
```
* install project dependencies
```sh
bundle install --path vendor/bundle
```
* install project Pods
``` sh
bundle exec pod install
```
* open the project with Xcode
``` sh
open FlowCrypt.xcworkspace
```

### Useful links

UI - [Texture documentation](https://texturegroup.org/docs/getting-started.html)

Storage - [Realm](https://github.com/realm)

Async Operations - [PromiseKit](https://github.com/mxcl/PromiseKit)

IMAP/SMTP provider - [MailCore](https://github.com/MailCore/mailcore2)

### Admin - generating .ipa for penetration tester

1) get uuid of their device and input it into https://developer.apple.com/account/ -> Devices
2) Xcode -> Product -> Archive
3) Distribute app -> Add Hoc -> Next -> Next (automatically manage signing)
4) This creates a folder at the target where you export it to, and the IPA will be there

### UI Tests

To run UI tests from Xcode: 
1) Select Tests in Navigators area (cmd+6)
2) Choose `FlowCryptUITests`
3) Run all tests, or select particular test to run

To run all UI tests from terminal:
1) Install dependencies 'bundle install'
2) Run tests using fastlane `bundle exec fastlane test_ui`

Before running tests, please make sure keyboard is visible in simulator. (cmd+shift+k)