# iOS UI tests with Appium

## Setup

1. You will need a secrets file at `appium/.env` - ask @tomholub to send it to you
2. This git repository must be located in `~/git/flowcrypt-ios/` so that `FlowCrypt.app` gets copied to the right place.
3. `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash`
4. `echo -e '\n\nexport NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"\n[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"\n' >> ~/.bash_profile`
5. restart terminal
6. `nvm install 16` - installs NodeJS 16 and sets it as default
7. `cd ~/git/flowcrypt-ios/appium && npm install`

## Run tests

Run this in `appium` folder. 

`npm test` - build `FlowCrypt.app` and run all ui tests

`npm run-script only.test.all` - run all ui tests without building the `.app`. Use this if you already built the `.app` before, and now only want to change the UI test spec without rebuilding the app

`npm run-script only.test.filter "user is able to view text email"` - run a particular ui test without building `.app`, filtered by name

## Inspect accessibility identifiers
1. Install `https://github.com/appium/appium-inspector`. Releases `https://github.com/appium/appium-inspector/releases`
2. Download `appium-inspector.dmg`.
3. Before openning package run `xattr -cr appium-inspector.dmg` on downloaded file.
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