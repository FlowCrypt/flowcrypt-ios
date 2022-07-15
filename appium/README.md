# iOS UI tests with Appium

## Setup

1. You will need a secrets file at `appium/.env` - ask @tomholub to send it to you
2. This git repository must be located in `~/git/flowcrypt-ios/` so that `FlowCrypt.app` gets copied to the right place.
3. `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash`
4. `echo -e '\n\nexport NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"\n[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"\n' >> ~/.bash_profile`
5. restart terminal
6. `nvm install 16` - installs NodeJS 16 and sets it as default
7. `cd ~/git/flowcrypt-ios/appium && npm install`
8. use Visual Studio Code IDE for editing appium tests - be sure to open it using `File` -> `Open Workspace from File` -> `flowcrypt-ios.code-workspace` (don't simply open the project as a folder, because advanced IDE functionality will be missing)

## Building app for testing
#### Option 1
- run `bundle exec fastlane build` in `flowcrypt-ios` folder
- this will build `FlowCrypt.app` app and move it to `appium` folder.

#### Option 2
- build app with Xcode
- copy `FlowCrypt.app` from `/DerivedData/FlowCrypt-.../Build/Products/Debug-iphonesimulator` *(In Xcode open Products folder -> FlowCrypt -> Show in Finder)*.

## Run tests

Run these in `appium` folder. `live` means real production APIs, `mock` means local mock APIs. 

To run a particular test:
- `npm run-script test.live "user is able to view text email"`
- `npm run-script test.mock "app setup fails with bad EKM URL"`

To run all tests: `npm run-script test.live.all` or `npm run-script test.mock.all`

## Write and debug tests
Tips for debugging:
- Remove contents of `appium/tmp` before test execution. 
- Execute tests and check `appium/tmp` for troubleshooting.
- You can change log level to debug/error inside `appium/config/wdio.shared.conf.js`. `logLevel: 'debug'`.
- You can inspect accessibility identifiers of ui elements with `appium-inspector`.
- if appium doesn't even start simulator where it used to work, try deleting node_modules folder and running `npm install`. Also check your nodejs version is 16 with `node --version`

## Inspect accessibility identifiers
 1. Install `https://github.com/appium/appium-inspector`. Releases `https://github.com/appium/appium-inspector/releases`
 2. Download `appium-inspector.dmg`.
 3. Before opening package run `xattr -cr appium-inspector.dmg` on downloaded file.
 4. Allow access in `System Prefferences -> Privacy Tab -> Accessibility`
 5. Use next capabilities for `Appium Inspector`  
 `
 {
 "platformName": "iOS",
 "iosInstallPause": 5000,
 "deviceName": "iPhone 13",
 "app": "*path to already buil app/FlowCrypt.app*",
 "platformVersion": "15.0",
 "automationName": "XCUITest",
 "newCommandTimeout": 10000,
 "wdaLaunchTimeout": 300000,
 "wdaConnectionTimeout": 600000,
 "wdaStartupRetries": 4,
 "wdaStartupRetryInterval": 120000
 }
 `  
 6. Remote host - `127.0.0.1`, Port - `4723`, Path - `/wd/hub`
 7. Run `Start Session`
