# flowcrypt-ios

![Build Status](https://flowcrypt.semaphoreci.com/badges/flowcrypt-ios.svg?key=9bd38bf4-4a38-4cb3-b551-38302af1eb07)

FlowCrypt iOS App, download from https://flowcrypt.com/download

### Installation

You will need to have Xcode *(version 12.4)* installed

```sh
# clone repo
git clone https://github.com/FlowCrypt/flowcrypt-ios.git && cd flowcrypt-ios
# set up environment
sudo xcode-select --install
curl -sSL https://get.rvm.io | bash -s stable
rvm install 3.0.2
rvm --default use 3.0.2
# install dependencies and pods
make dependencies
bundle exec pod install
```

### Run UI Tests

Follow steps in installation above, and then:
 - from terminal: 
    - `make ui_tests` - for all ui tests
    - `make ui_tests_gmail` - for Gmail ui tests
    - `make ui_tests_imap` - for Imap ui tests
 - from Xcode:  
    1) Choose `FlowCryptUITests` run target on top and select a simulator 
    2) select Tests in Navigators area (cmd+6) 
    3) Scroll down to `FlowCryptUITests` in the navigator and run them all or run a particular one

Before running tests, please make sure keyboard is visible in simulator. (cmd+shift+k)

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
