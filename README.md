# flowcrypt-ios

![Build Status](https://flowcrypt.semaphoreci.com/badges/flowcrypt-ios.svg?key=9bd38bf4-4a38-4cb3-b551-38302af1eb07)

FlowCrypt iOS App, download from https://flowcrypt.com/download

## Installation

You will need to have Xcode - latest version - installed.

```sh
# clone repo
git clone https://github.com/FlowCrypt/flowcrypt-ios.git && cd flowcrypt-ios
# this is to setup husky and eslint
npm install
# set up environment
sudo xcode-select --install
curl -sSL https://get.rvm.io | bash -s stable
rvm install 3.0.2
rvm --default use 3.0.2
# install dependencies
make dependencies
```

## Development

Recommended to develop and run tests only using `Debug FlowCrypt` scheme

## Code Design
See [Code Design README](./code-design.md)

## UI Tests

See [Appium README](./appium/README.md)

## Dependency docs

- UI - [Texture documentation](https://texturegroup.org/docs/getting-started.html)
- Storage - [Realm](https://github.com/realm)
- IMAP/SMTP provider - [MailCore](https://github.com/MailCore/mailcore2)
- icons - use https://developer.apple.com/sf-symbols/

## Admin - generating .ipa for penetration tester

1) get uuid of their device and input it into https://developer.apple.com/account/ -> Devices
2) choose the right build (eg `FlowCrypt Enterprise`) and choose `Any iOS Device (arm64)`
3) Xcode -> Product -> Archive
4) Distribute app -> Add Hoc -> Next -> Next (automatically manage signing)
5) This creates a folder at the target where you export it to, and the IPA will be there
