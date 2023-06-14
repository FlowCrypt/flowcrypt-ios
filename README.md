# FlowCrypt iOS App (Encrypt email with PGP)

![Build Status](https://flowcrypt.semaphoreci.com/badges/flowcrypt-ios.svg?key=9bd38bf4-4a38-4cb3-b551-38302af1eb07)

| &#8678; Prerequisites                                                                                          |
|:---------------------------------------------------------------------------------------------------------------|
| Download the FlowCrypt app on your device from the [FlowCrypt Downloads](https://flowcrypt.com/download) page. |

## Installation

You'll need to have the latest version of Xcode installed.

To run the app, you need to follow these instructions:

```sh
# 1. Clone the repository
git clone https://github.com/FlowCrypt/flowcrypt-ios.git && cd flowcrypt-ios
# 2. To set up Husky and ESLint
npm install
# 3. Set up your environment
sudo xcode-select --install
curl -sSL https://get.rvm.io | bash -s stable
rvm install 3.0.2
rvm --default use 3.0.2
# 4. Install SwiftFormat
brew install swiftformat
# 5. Install the dependencies
make dependencies
```

## Development

We recommended developing and running tests only using the `Debug FlowCrypt` scheme.

## Code Design

Please refer to our [Code Design README](./code-design.md) to learn how we handle errors and tasks.

## UI Tests

Please refer to our [Appium README](./appium/README.md) for UI tests. It explains how to configure your environment, build the app, write, run, and debug tests.

## Dependency docs

- UI: We use [Texture](https://texturegroup.org/docs/getting-started.html) to improve the performance, memory efficiency, and thread safety of the app.
- Storage: We use [Realm](https://www.mongodb.com/docs/realm/sdk/swift/realm-database/) as an alternative to SQLite.      [Realm](https://github.com/realm/realm-swift)
- IMAP/SMTP provider: We use [MailCore](http://libmailcore.com/api/objc/index.html) which provides an asynchronous API to work with the e-mail protocols.
- Icons: We use [SF Symbols](https://developer.apple.com/sf-symbols/), a powerful resource for vast collection of vector-based icons.

## Admin - generating .ipa for penetration tester

1\. Get the UUID of their device and input it into [Apple Developer](https://developer.apple.com/account/) account &#10140; **Devices**.
2\. Choose the right build (e.g. `FlowCrypt Enterprise`) and choose `Any iOS Device (arm64)`.
3\. **Xcode** &#10140; **Product** &#10140; **Archive**.
4\. Distribute app &#10140; **Add Hoc** &#10140; **Next** &#10140; **Next** (automatically manage signing).
5\. This creates a folder at the target where you export it to, and the IPA will be there.
